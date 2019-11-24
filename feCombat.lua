-- Enemy phase behavior no longer supported.
-- Value provided doesn't justify maintaining feature,
-- as enemy phase events can't be permuted and the burns are unpredictable.
-- Instead implement rn advancing to enable fast enemy phase trials.
-- Therefore attacker is always the player.

require("feVersion")
require("feRandomNumbers")
require("feClass")

local P = {}
combat = P

local battleSimBase = {} 
battleSimBase[6] = 0x02039200
battleSimBase[7] = 0x0203A400
battleSimBase[8] = 0x0203A500
P.ATTACK_I 	= 1 -- includes weapon triangle, 0xFF when healing (staff?) or not attacking?
P.DEF_I 	= 2 -- includes terrain bonus
P.AS_I 		= 3 -- Attack speed
P.HIT_I 	= 4 -- if can't attack, 0xFF
P.CRIT_I 	= 5 
P.HP_I 		= 6 -- current HP
P.LEVEL_I	= 7 -- for Great Shield, Pierce, Sure Strike, and exp cap at level 19
P.EXP_I		= 8 -- for level up detection
P.LUCK_I	= 9 -- for devil axe, not read from memory here
local relativeBattleAddrs = {}
--						  atk   def   AS    hit   crit  hp    lvl   xp
relativeBattleAddrs[6] = {0x6C, 0x6E, 0x70, 0x76, 0x7C, 0x82, 0x80, 0x81}
relativeBattleAddrs[7] = {0x4A, 0x4C, 0x4E, 0x54, 0x5A, 0x62, 0x60, 0x61}
relativeBattleAddrs[8] = {0x46, 0x48, 0x4A, 0x50, 0x56, 0x5E, 0x5C, 0x5D}
--						  0		+2    +2    +6    +6    +8    -2    +1
local defenderBattleAddrs = {}
defenderBattleAddrs[6] = 0x7C
defenderBattleAddrs[7] = 0x80
defenderBattleAddrs[8] = 0x80

-- note that staff hit only updates in animation, not in preview
-- in preview, p/e crit and p hit are set to 255 as well
-- therefore, normal combat can be set in preview or after RNs used
-- staff can only be set after RN used

-- special weapon types, index from 1 so WEAPON_TYPE_STRINGS works
P.enum_NORMAL = 1
P.enum_DEVIL  = 2
P.enum_DRAIN  = 3 -- nosferatu
P.enum_BRAVE  = 4
P.enum_HALVE  = 5
P.enum_STONE  = 6
P.enum_POISON = 7

P.WEAPON_TYPE_STRINGS = {"normal", "devil", "drain", "brave", "halve", "stone", "poison"}

local ATTACKER = true
local DEFENDER = false
local PLAYER = true
local ENEMY = false

local function battleAddrs(isAttacker, index)
	if isAttacker then
		return battleSimBase[version] + relativeBattleAddrs[version][index]		
	end
	return battleSimBase[version] + relativeBattleAddrs[version][index] + defenderBattleAddrs[version]
end

P.combatObj = {}

function P.combatObj:new()
	local o = {}
	setmetatable(o, self)
	self.__index = self
	
	o.attacker = {0, 0, 0, 0, 0, 0, 0, 0, 0}
	o.attacker.class = classes.LORD
	o.attacker.weapon = P.enum_NORMAL
	
	
	o.defender = {0, 0, 0, 0, 0, 0, 0, 0, 0}
	o.defender.class = classes.LORD
	o.defender.weapon = P.enum_NORMAL
	
	o.player = o.attacker -- alias, sometimes one description makes more sense
	o.enemy = o.defender
	
	o.unit_ID  = 1
	o.bonusExp = 0 -- 20 for killing thief, 40 for killing boss
	
	return o
end

function P.combatObj:copy()
	local o = {}
	setmetatable(o, self)
	self.__index = self
	
	o.attacker = {}
	o.defender = {}
	for i = 1, P.LUCK_I do
		o.attacker[i] = self.attacker[i]
		o.defender[i] = self.defender[i]
	end
	o.attacker.class  = self.attacker.class
	o.attacker.weapon = self.attacker.weapon
	o.defender.class  = self.defender.class
	o.defender.weapon = self.defender.weapon
	
	o.player = o.attacker
	o.enemy = o.defender
	
	o.unit_ID  = self.unit_ID
	o.bonusExp = self.bonusExp
	
	return o
end

function P.combatObj:data(isAttacker)
	if isAttacker then return self.attacker end
	return self.defender
end

function P.combatObj:staff()
	return self.attacker[P.ATTACK_I] == 255 -- healing only?
end

function P.combatObj:dmg(isAttacker, pierce)
	if pierce then
		return self:data(isAttacker)[P.ATTACK_I]
	end
	return math.max(0, self:data(isAttacker)[P.ATTACK_I] - self:data(not isAttacker)[P.DEF_I])
end

function P.combatObj:relAS() -- relative attack speed from attacker's perspective
	return self.attacker[P.AS_I] - self.defender[P.AS_I]
end

function P.combatObj:doubles(isAttacker)
	return (self:relAS() >= 4 and isAttacker) or 
	(self:relAS() <= -4 and not isAttacker)
end

function P.combatObj:togglePromo(isAttacker)
	self:data(isAttacker)[P.LEVEL_I] = (self:data(isAttacker)[P.LEVEL_I] + 19) % 40 + 1
end

function P.combatObj:set()
	for i = 1, 8 do
		self.attacker[i] = memory.readbyte(battleAddrs(true, i))
		self.defender[i] = memory.readbyte(battleAddrs(false, i))
	end
	
	self.unit_ID = unitData.sel_Unit_i
	self.player.class = unitData.class(self.unit_ID)
	
	if classes.PROMOTED[self.player.class] then
		self:togglePromo(PLAYER)
	end
	
	self.bonusExp = 0
end

function P.combatObj:cycleWeapon(isAttacker)
	self:data(isAttacker).weapon = rotInc(self:data(isAttacker).weapon, 5)
	-- for devil axe, todo enemy devil axe?
	self:data(isAttacker)[P.LUCK_I] = unitData.getSavedStats()[unitData.LUCK_I]
	print(P.WEAPON_TYPE_STRINGS[self:data(isAttacker).weapon])
end

function P.combatObj:cycleEnemyClass()
	self.enemy.class = classes.nextRelevantEnemyClass(self.enemy.class)
end

function P.combatObj:toggleBonusExp()
	self.bonusExp = (self.bonusExp + 20) % 60
	print(string.format("bonus xp: %d", self.bonusExp)) 
end

local function hitToString(hit)
	if hit <= 100 then return string.format("%3d", hit) end
	return string.format("%02X", hit)
end

function P.combatObj:toStrings()
	local rStrings = {}
	rStrings[1] = "          LV.XP Hit Crt HP Dmg"
	if self:staff() then 
		rStrings[1] = "STAFF     LV.XP Hit Crt HP Dmg" 
	end
	
	local function line(isAttacker)
		local name = unitData.names(self.unit_ID)
		local experStr = string.format("%02d", self:data(isAttacker)[P.EXP_I])
		if not isAttacker then
			name = "Enemy"
		end
		if self:data(isAttacker)[P.EXP_I] > 100 then
			experStr = string.format("%02X", self:data(isAttacker)[P.EXP_I])
		end
		
		local rLine = string.format("%-10.10s%2d.%s %3s %3s %2d %2d",
			name, self:data(isAttacker)[P.LEVEL_I], experStr, 
			hitToString(self:data(isAttacker)[P.HIT_I]), 
			hitToString(self:data(isAttacker)[P.CRIT_I]), 
			self:data(isAttacker)[P.HP_I], self:dmg(isAttacker))
		
		if self:doubles(isAttacker) then rLine = rLine .. "x2" 
		else rLine = rLine .. "  " end	
		
		if self:data(isAttacker).weapon ~= P.enum_NORMAL then
			rLine = rLine .. " " .. P.WEAPON_TYPE_STRINGS[self:data(isAttacker).weapon]
		end
		return rLine
	end
	
	rStrings[2] = line(ATTACKER)
	rStrings[3] = line(DEFENDER)
	
	return rStrings
end

local function trueHit(hit)
	if hit <= 50 then
		return hit*(2*hit+1)/100
	end
	return 100 - trueHit(100 - hit)
end

-- for compact display during EP, just display attacker then defender
-- hp and xp show up on screen even with animations off
function P.combatObj:toCompactStrings()
	local rStrings = {}	
	rStrings[1] = "Dmg  trHit Cr"
	
	local function line(isAttacker)
		local rLine = ""
		
		local dmg = self:dmg(isAttacker)
		if dmg >= 100 then 
			rLine = rLine .. "--   "
		else
			rLine = rLine .. string.format("%2d",self:dmg(isAttacker))
			if self:doubles(isAttacker) then rLine = rLine .. "x2 " 
			else rLine = rLine .. "   " end
		end
		
		local hit = self:data(isAttacker)[P.HIT_I]
		if hit > 100 then rLine = rLine .. " --- "
		elseif hit == 100 then rLine = rLine .. "100.0"
		else rLine = rLine .. string.format("%05.2f", trueHit(hit))
		end
		
		local crit = self:data(isAttacker)[P.CRIT_I]
		if crit > 100 then rLine = rLine .. " --"
		else rLine = rLine .. string.format(" %2d", crit)
		end
		
		return rLine
	end
	
	rStrings[2] = line(ATTACKER)
	rStrings[3] = line(DEFENDER)
	
	return rStrings
end

function P.combatObj:canLevel()
	return self.player[P.LEVEL_I] % 20 ~= 0
end

function P.combatObj:willLevel(XPgained)
	return self:canLevel() and (self.player[P.EXP_I]+XPgained >= 100)
end

function P.combatObj:expFrom(kill, assassinated) --http://serenesforest.net/the-sacred-stones/miscellaneous/calculations/
	if not self:canLevel() then return 0 end
	
	local playerClass = self.player.class
	local playerClassPower = classes.EXP_POWER[playerClass]	
	local expFromDmg = math.max(1,
		(31+self.enemy[P.LEVEL_I]-self.player[P.LEVEL_I])/playerClassPower)
	
	local rExpFrom = expFromDmg
	
	if kill then
		-- todo: load enemy class from RAM?
		local enemyClass = self.enemy.class
		local enemyClassPower = classes.EXP_POWER[enemyClass]
		
		local enemyValue = self.enemy[P.LEVEL_I]*enemyClassPower
			+classes.EXP_KILL_MODIFIER[enemyClass]
		local playerValue = self.player[P.LEVEL_I]*playerClassPower
			+classes.EXP_KILL_MODIFIER[playerClass]
		
		local assassinateMult = 1
		if assassinated then
			assassinateMult = 2 -- doubles exp from kill?
			-- https://serenesforest.net/forums/index.php?/topic/78394-simplifying-and-correcting-the-experience-calculations/
		end
		
		-- if FE7 normal mode, or FE8. note this gains a lot of exp 
		-- from killing an equal or slightly "weaker" enemy,
		-- especially at high levels, up to level*1.5.
		-- a level 39 killing a level 39 gets ~68 exp more
		-- than a level 39 killing a level 40.
		-- final Ursula gets a "value" reduction of -20 due to being a valkyrie
		-- so this effect is easily observable at Final
		
		-- inconsistent in FE8? on Ephraim mode, 
		-- Gilliam lvl 10 killing fighter lvl 9
		-- gains 27, not 42 xp??
		-- yet Franz lvl 26 killing Entombed lvl 24 gains 55, not 15 exp?
		-- in same level, Gilliam doesn't get this "mode bonus" when he otherwise would
		
		-- hypothesis: only affects promoted (enemy or player?) or boss units? in FE8?
		if enemyValue - playerValue <= 0 and version ~= 6 
			--and self.bonusExp == 40 
			then
			playerValue = math.floor(playerValue/2)
		end
		
		-- eggs always yield 50xp
		
		rExpFrom = math.min(100, math.floor(expFromDmg+assassinateMult*math.max(0, 
			enemyValue-playerValue + 20 + self.bonusExp)))
	end
	
	if self.player[P.LEVEL_I] % 20 == 19 then
		return math.min(math.floor(rExpFrom), 100 - self.player[P.EXP_I])
	end
	
	return math.floor(rExpFrom)
end

-- string action type, int dmg, int rnsConsumed, bool expWasGained, bool assassinated
function P.combatObj:hitEvent(index, isAttacker)
	local retHitEv = {}
	retHitEv.action = ""
	retHitEv.RNsConsumed = 0
	retHitEv.dmg = self:dmg(isAttacker)
	
	if self:data(isAttacker).weapon == P.enum_STONE then
		retHitEv.dmg = 999
	end
	
	-- todo
	if self:data(isAttacker).weapon == P.enum_HALVE then
		--retHitEv.dmg = 999 
	end
	
	retHitEv.expWasGained = isAttacker -- assume true and falsify
	retHitEv.assassinated = false
	
	local hit = self:data(isAttacker)[P.HIT_I]
	local crt = self:data(isAttacker)[P.CRIT_I]
	local lvl = self:data(isAttacker)[P.LEVEL_I]
	
	if lvl > 20 then
		lvl = lvl - 20
	end
	
	local function nextRn()
		retHitEv.RNsConsumed = retHitEv.RNsConsumed + 1
		return rns.rng1:getRNasCent(index+retHitEv.RNsConsumed-1)--use consumed rn
	end
		
	if hit ~= 255 then -- no action	
		local willHit = (hit > (nextRn()+nextRn())/2)
		
		if classes.hasSureStrike(self:data(isAttacker).class) then
			if lvl > nextRn() then
				willHit = true
			end
		end
		
		if willHit then
			retHitEv.action = "X"
			
			-- confirmed gShield, Pierce, crit, Silencer order
			-- then Devil?
			
			if classes.hasGreatShield(self:data(not isAttacker).class) then
				if lvl > nextRn() then
					retHitEv.action = "G" -- does crit even roll?
					retHitEv.dmg = 0
				end
			end
			
			if classes.hasPierce(self:data(isAttacker).class) then
				if lvl > nextRn() then
					retHitEv.action = "P"
					retHitEv.dmg = self:dmg(isAttacker, true)
				end
			end
			
			if crt > nextRn() then
				local silencerRn = 0
				if version >= 7 then 
					silencerRn = nextRn() -- does not roll against Demon King
				end
				
				if classes.hasSilencer(self:data(isAttacker).class) and
					(25 > silencerRn or -- bosses are resistant to silencer
					(50 > silencerRn and self.bonusExp ~= 40)) then
					
					retHitEv.action = "S"
					retHitEv.dmg = 999
					retHitEv.assassinated = true
				else
					if retHitEv.action == "P" then
						retHitEv.action = "PC"
					else
						retHitEv.action = "C"
					end
					
					retHitEv.dmg = 3*retHitEv.dmg
				end
			end
			
			-- crit/devil priority?
			if self:data(isAttacker).weapon == P.enum_DEVIL then
				local devilRN = nextRn()
			
				if ((31 - self:data(isAttacker)[P.LUCK_I] > devilRN) and (version >= 7)) or 
					((21 - self:data(isAttacker)[P.LEVEL_I] > devilRN) and (version == 6)) then
					retHitEv.action = "DEV"
					retHitEv.expWasGained = false -- untested
				end
			end
		else
			retHitEv.action = "O"
			retHitEv.dmg = 0
			retHitEv.expWasGained = false
		end
	end
	
	return retHitEv
end

function P.combatObj:staffHitEvent(index)
	local retStvHitEv = {}
	retStvHitEv.action = "STF-X"
	retStvHitEv.RNsConsumed = 1
	retStvHitEv.dmg = 0
	retStvHitEv.expWasGained = true
	
	if self.attacker[P.HIT_I] <= rns.rng1:getRNasCent(index) then
		retStvHitEv.action = "STF-O"
		retStvHitEv.expWasGained = false
	end
	
	return retStvHitEv
end

-- variable number of events, 1 to 6
-- X hit events, expGained, lvlUp, totalRNsConsumed, pHP, eHP
-- can carry enemies hp from previous combat
function P.combatObj:hitSeq(index, carriedEnemyHP)
	local rHitSeq = {} -- numeric keys are hit events
	local isAttackers = {} -- unnecessary to return with current functionality
	rHitSeq.expGained = 1
	rHitSeq.lvlUp = false
	rHitSeq.totalRNsConsumed = 0
	rHitSeq.pHP = self.player[P.HP_I]
	
	-- pass enemy HP from previous combats this phase if applicable
	rHitSeq.eHP = carriedEnemyHP or self.enemy[P.HP_I]
	if rHitSeq.eHP == 0 then
		rHitSeq.expGained = 0
		return rHitSeq
	end
	
	if self:staff() then 
		rHitSeq[1] = self:staffHitEvent(index)
		isAttackers[1] = true
		rHitSeq.totalRNsConsumed = 1
		return rHitSeq
	end
	
	local function setNext(isAttacker)
		table.insert(isAttackers, isAttacker)
		if self:data(isAttacker).weapon == P.enum_BRAVE then
			table.insert(isAttackers, isAttacker)
		end
	end
	
	setNext(ATTACKER)
	defenderCounters = (self.defender[P.HIT_I] ~= 255)
	
	if defenderCounters then
		setNext(DEFENDER)
	end
	
	if self:doubles(ATTACKER) and self.attacker.weapon ~= P.enum_HALVE then
		setNext(ATTACKER)
	elseif self:doubles(DEFENDER) and defenderCounters then
		setNext(DEFENDER)
	end
	
	for ev_i, isAttacker in ipairs(isAttackers) do
		local hE = self:hitEvent(index, isAttacker)
	
		rHitSeq[ev_i] = hE
		index = index + hE.RNsConsumed
		rHitSeq.totalRNsConsumed = rHitSeq.totalRNsConsumed + hE.RNsConsumed
		
		if (isAttacker and hE.action ~= "DEV") or 
			(not isAttacker and hE.action == "DEV") then 
			rHitSeq.eHP = rHitSeq.eHP - hE.dmg -- player or enemy-devil damage
		else
			rHitSeq.pHP = rHitSeq.pHP - hE.dmg -- enemy or self-devil damage
		end
		
		if hE.expWasGained then
			rHitSeq.expGained = self:expFrom()
			rHitSeq.lvlUp = self:willLevel(rHitSeq.expGained)
		end
		
		if not isAttacker then
			rHitSeq[ev_i].action = string.lower(hE.action)
		end
		
		if rHitSeq.pHP <= 0 then  -- player died, combat over
			rHitSeq.pHP = 0
			rHitSeq.expGained = 0
			rHitSeq.lvlUp = false
			return rHitSeq
		end
		
		if rHitSeq.eHP <= 0 then  -- enemy died, combat over
			rHitSeq.eHP = 0
			rHitSeq.expGained = self:expFrom(true, hE.assassinated)
			rHitSeq.lvlUp = self:willLevel(rHitSeq.expGained)
			return rHitSeq
		end
	end
	return rHitSeq
end

function P.hitSeq_string(argHitSeq)
	local hitString = ""
	
	for _, hitEvent in ipairs(argHitSeq) do
		hitString = hitString .. hitEvent.action .. " "
	end
	
	hitString = hitString .. string.format("%2dxp", argHitSeq.expGained)
	if argHitSeq.lvlUp then hitString = hitString .. " Lvl" end
	return hitString
end

function P.combatObj:RNsConsumedAt(index)
	return self:hitSeq(index).totalRNsConsumed
end

P.currBattleParams = combat.combatObj:new()

return combat
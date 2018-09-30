require("feVersion")
require("feRandomNumbers")
require("feClass")

local P = {}
combat = P

local battleSimBase = {} 
battleSimBase[6] = 0x02039200
battleSimBase[7] = 0x0203A400
battleSimBase[8] = 0x0203A500
P.MIGHT_I 	= 1 -- includes weapon triangle, 0xFF when healing (staff?) or not attacking?
P.DEF_I 	= 2 -- includes terrain bonus
P.AS_I 		= 3 -- Attack speed
P.HIT_I 	= 4 -- if can't attack, 0xFF
P.CRIT_I 	= 5 
P.HP_I 		= 6 -- current HP
P.LEVEL_I	= 7 -- for Great Shield, Pierce, and Sure Strike
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
P.enum_POISON = 5

P.WEAPON_TYPE_STRINGS = {"normal", "devil", "drain", "brave", "poison"}

local function battleAddrs(attacker, index)
	if attacker then
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
	o.attacker.class = classes.F.LORD
	o.attacker.weapon = P.enum_NORMAL
	o.defender = {0, 0, 0, 0, 0, 0, 0, 0, 0}
	o.defender.class = classes.F.LORD
	o.defender.weapon = P.enum_NORMAL
	
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
	
	o.unit_ID  = self.unit_ID
	o.bonusExp = self.bonusExp
	
	return o
end

-- sometimes want data based on player/enemy, sometimes attacker/defender
P.enum_ATTACKER = 0
P.enum_DEFENDER = 1
P.enum_PLAYER 	= 2
P.enum_ENEMY 	= 3
P.enum_NO_ONE	= 4

function P.opponent(who)
	if (who % 2 == 0) then return who + 1 end
	return who - 1
end

-- if attacker can't gain exp, enemy (unless lvl 20 friendly unit)
-- if defender can't gain exp too, assume player phase
-- fails only in case of enemy phase attacking level 20 player unit
function P.combatObj:playerPhase()
	return self.attacker[P.EXP_I] ~= 255 -- attacker can gain exp, player
		or self.defender[P.EXP_I] == 255 -- neither attacker nor defender can gain
end

function P.combatObj:isAttacker(who)
	return (who == P.enum_ATTACKER) or 
	(who == P.enum_PLAYER and self:playerPhase()) or 
	(who == P.enum_ENEMY and not self:playerPhase())
end

function P.combatObj:isPlayer(who)
	return (who == P.enum_PLAYER) or
	(who == P.enum_ATTACKER and self:playerPhase()) or 
	(who == P.enum_DEFENDER and not self:playerPhase())
end

-- todo
-- level does not update, might given as 0xFF as any non-attacker
function P.combatObj:defenderIsWall()
	return false 
	-- self.defender[P.LEVEL_I] < 20 and self.defender[P.EXP_I] > 99
end

function P.combatObj:data(who)
	if self:isAttacker(who) then return self.attacker end
	return self.defender
end

function P.combatObj:staff()
	return self.attacker[P.MIGHT_I] == 255 -- healing only?
end

function P.combatObj:dmg(who, pierce)
	if pierce then
		return self:data(who)[P.MIGHT_I]
	end
	return math.max(0, self:data(who)[P.MIGHT_I] - self:data(P.opponent(who))[P.DEF_I])
end

function P.combatObj:relAS() -- from attacker perspective
	return self.attacker[P.AS_I] - self.defender[P.AS_I]
end

function P.combatObj:doubles(who)
	return (self:relAS() >= 4 and self:isAttacker(who)) or 
	(self:relAS() <= -4 and not self:isAttacker(who))
end

function P.combatObj:togglePromo(who)
	who = who or P.enum_ENEMY

	-- don't loop 40 to zero
	self:data(who)[P.LEVEL_I] = (self:data(who)[P.LEVEL_I] + 19) % 40 + 1
end

function P.combatObj:set()
	for i = 1, 8 do
		self.attacker[i] = memory.readbyte(battleAddrs(true, i))
		self.defender[i] = memory.readbyte(battleAddrs(false, i))
	end
	
	self.unit_ID = unitData.sel_Unit_i
	self:data(P.enum_PLAYER).class = unitData.class(self.unit_ID)
	
	if classes.PROMOTED[self:data(P.enum_PLAYER).class] then
		self:togglePromo(P.enum_PLAYER)
	end
	
	self.bonusExp = 0
end

function P.combatObj:cycleWeapon(who)
	who = who or P.enum_PLAYER
	self:data(who).weapon = rotInc(self:data(who).weapon, 4)
	-- for devil axe
	self:data(who)[P.LUCK_I] = unitData.getSavedStats()[unitData.LUCK_I]
	print(P.WEAPON_TYPE_STRINGS[self:data(who).weapon])
end

function P.combatObj:cycleEnemyClass()
	self:data(P.enum_ENEMY).class = classes.nextRelevantEnemyClass(self:data(P.enum_ENEMY).class)
end

function P.combatObj:toggleBonusExp()
	self.bonusExp = (self.bonusExp + 20) % 60
	print(string.format("bonus xp: %d", self.bonusExp)) 
end

-- converts 255/0xFF/-1 to "---"
local function hitToString(hit)
	if hit == 255 then return "---" end
	return string.format("%3d", hit)
end

function P.combatObj:toStrings()
	local ret = {}	
	ret[0] = "          LV.XP Hit Crt HP Dmg"
	if self:staff() then 
		ret[0] = "STAFF     LV.XP Hit Crt HP Dmg" 
	end

	local function line(who)
		local name = unitData.names(self.unit_ID)		
		local experStr = string.format("%02d", self:data(who)[P.EXP_I])
		if not self:isPlayer(who) then
			name = "Enemy"
		end
		if self:data(who)[P.EXP_I] == 255 then
			experStr = "--"
		end
		
		local ret = string.format("%-10.10s%2d.%s %3s %3s %2d %2d",
			name, self:data(who)[P.LEVEL_I], experStr, 
			hitToString(self:data(who)[P.HIT_I]), 
			hitToString(self:data(who)[P.CRIT_I]), 
			self:data(who)[P.HP_I], self:dmg(who))
		
		if self:doubles(who) then ret = ret .. "x2" 
		else ret = ret .. "  " end	
		
		if self:data(who).weapon ~= P.enum_NORMAL then
			ret = ret .. " " .. P.WEAPON_TYPE_STRINGS[self:data(who).weapon]
		end
		return ret
	end
	
	ret[1] = line(P.enum_ATTACKER)
	ret[2] = line(P.enum_DEFENDER)
	
	return ret
end

function P.trueHit(hit)
	if hit <= 50 then
		return hit*(2*hit+1)/100
	end
	return 100 - P.trueHit(100 - hit)
end

-- for compact display during EP, just display attacker then defender
-- hp and xp show up on screen even with animations off
function P.combatObj:toCompactStrings()
	local ret = {}	
	ret[0] = "Dmg  trHit Cr"
	
	local function line(who)
		local ret = ""
		
		local dmg = self:dmg(who)
		if dmg >= 100 then 
			ret = ret .. "--   "
		else
			ret = ret .. string.format("%2d",self:dmg(who))
			if self:doubles(who) then ret = ret .. "x2 " 
			else ret = ret .. "   " end
		end
		
		local hit = self:data(who)[P.HIT_I]		
		if hit > 100 then ret = ret .. " --- "
		elseif hit == 100 then ret = ret .. "100.0"
		else ret = ret .. string.format("%05.2f", P.trueHit(hit))
		end
		
		local crit = self:data(who)[P.CRIT_I]
		if crit > 100 then ret = ret .. " --"
		else ret = ret .. string.format(" %2d", crit)
		end

		return ret
	end
	
	ret[1] = line(P.enum_ATTACKER)
	ret[2] = line(P.enum_DEFENDER)
	return ret
end

function P.combatObj:canLevel()
	return self:data(P.enum_PLAYER)[P.LEVEL_I] % 20 ~= 0
end

function P.combatObj:willLevel(XPgained)
	return self:canLevel() and (self:data(P.enum_PLAYER)[P.EXP_I]+XPgained >= 100)
end

function P.combatObj:expFrom(kill, silenced) --http://serenesforest.net/the-sacred-stones/miscellaneous/calculations/
	if (not self:canLevel() or self:defenderIsWall()) then return 0 end
	
	local playerClass = self:data(P.enum_PLAYER).class
	local playerClassPower = classes.EXP_POWER[playerClass]	
	local expFromDmg = math.max(1,
		(31+self:data(P.enum_ENEMY)[P.LEVEL_I]
		   -self:data(P.enum_PLAYER)[P.LEVEL_I])/playerClassPower)
	
	if kill then
		-- todo: load enemy class from RAM?
		local enemyClass = self:data(P.enum_ENEMY).class
		local enemyClassPower = classes.EXP_POWER[enemyClass]
		
		local enemyValue = self:data(P.enum_ENEMY)[P.LEVEL_I]*enemyClassPower
			+classes.EXP_KILL_MODIFIER[enemyClass]
		local playerValue = self:data(P.enum_PLAYER)[P.LEVEL_I]*playerClassPower
			+classes.EXP_KILL_MODIFIER[playerClass]
		
		local silencerMult = 1
		if silenced then
			silencerMult = 2 -- doubles exp from kill?
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
		
		-- hypothesis: only affects promoted (enemy or player?) or boss units?
		if enemyValue - playerValue <= 0 and version ~= 6 and self.bonusExp == 40 then
			playerValue = math.floor(playerValue/2)
		end
		
		return math.min(100, math.floor(expFromDmg+silencerMult*math.max(0, 
			enemyValue-playerValue + 20 + self.bonusExp)))
	end
	return math.floor(expFromDmg)
end

-- string action type, int dmg, int rnsConsumed, bool expGained, bool silenced
function P.combatObj:hitEvent(index, who)
	local retHitEv = {}
	retHitEv.action = ""
	retHitEv.RNsConsumed = 0
	retHitEv.dmg = self:dmg(who)
	retHitEv.expGained = true -- assume true and falsify
	
	if (not self:isPlayer(who)) or self:defenderIsWall() then
		retHitEv.expGained = false
	end
	retHitEv.silenced = false
	
	local hit = self:data(who)[P.HIT_I]
	local crt = self:data(who)[P.CRIT_I]
	local lvl = self:data(who)[P.LEVEL_I]
	
	if lvl > 20 then
		lvl = lvl - 20
	end
	
	-- gShield or Pierce consumed first if applicable (gShield before Pierce?)
	-- then crit
	-- then Silencer if crit (regardless of whether unit has Silencer) 
	-- then Devil?
	-- todo test sure strike
	
	local function nextRn()
		retHitEv.RNsConsumed = retHitEv.RNsConsumed + 1
		return rns.rng1:getRNasCent(index+retHitEv.RNsConsumed-1)--use consumed rn
	end
		
	if hit ~= 255 then -- no action	
		local willHit = (hit > (nextRn()+nextRn())/2)
		
		if classes.hasSureStrike(self:data(who).class) then
			if nextRn() < lvl then
				willHit = true
			end
		end
	
		if willHit then
			retHitEv.action = "X"
			
			if classes.hasGreatShield(self:data(P.opponent(who)).class) then
				if lvl > nextRn() then
					retHitEv.action = "G" -- does crit even roll?
					retHitEv.dmg = 0
				end
			end
			
			if classes.hasPierce(self:data(who).class) then
				if lvl > nextRn() then
					retHitEv.action = "P"
					retHitEv.dmg = self:dmg(who, true)
				end
			end
			
			if crt > nextRn() then
				local silencerRn = 0
				if version >= 7 then 
					silencerRn = nextRn()
				end
				
				if classes.hasSilencer(self:data(who).class) and
					(25 > silencerRn or -- bosses are resistant to silencer
					(50 > silencerRn and self.bonusExp ~= 40)) then
					
					retHitEv.action = "S"
					retHitEv.dmg = 999
					retHitEv.silenced = true
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
			if self:data(who).weapon == P.enum_DEVIL then
				local devilRN = nextRn()
			
				if ((31 - self:data(who)[P.LUCK_I] > devilRN) and (version >= 7)) or 
					((21 - self:data(who)[P.LEVEL_I] > devilRN) and (version == 6)) then
					retHitEv.action = "DEV"
					retHitEv.expGained = false -- untested	
				end
			end
		else
			retHitEv.action = "O"
			retHitEv.dmg = 0
			retHitEv.expGained = false
		end
	end
	
	return retHitEv
end

function P.combatObj:staffHitEvent(index)
	local retStvHitEv = {}
	retStvHitEv.action = "STF-X"
	retStvHitEv.RNsConsumed = 1
	retStvHitEv.dmg = 0
	retStvHitEv.expGained = true
	
	if self.attacker[P.HIT_I] <= rns.rng1:getRNasCent(index) then
		retStvHitEv.action = "STF-O"
		retStvHitEv.expGained = false
	end
	
	return retStvHitEv
end

function P.isStaffHit(event) 
	return event.action == "STF-X"
end

-- variable number of events, 1 to 6
-- X hit events, numEvents, expGained, lvlUp, totalRNsConsumed, pHP, eHP
-- can carry enemies hp from previous combat
function P.combatObj:hitSeq(index, carriedEnemyHP)
	local ret = {} -- direct index access are hit events
	local whos = {} -- unnecessary to return with current functionality
	ret.numEvents = 0
	ret.expGained = 1
	ret.lvlUp = false
	ret.totalRNsConsumed = 0
	ret.pHP = self:data(P.enum_PLAYER)[P.HP_I]
	
	-- pass enemy HP from previous combats this phase if applicable
	ret.eHP = carriedEnemyHP or self:data(P.enum_ENEMY)[P.HP_I]
	if ret.eHP == 0 then
		ret.expGained = 0
		return ret
	end	
	
	local maxEvents = 0 -- combat can end early in death
		
	if self:staff() then 
		ret.numEvents = 1
		ret[1] = self:staffHitEvent(index)
		whos[1] = P.enum_ATTACKER
		ret.totalRNsConsumed = 1
		return ret
	end
	
	local function setNext(who)
		maxEvents = maxEvents + 1
		whos[maxEvents] = who
		if self:data(who).weapon == P.enum_BRAVE then			
			maxEvents = maxEvents + 1
			whos[maxEvents] = who
		end
	end
	
	setNext(P.enum_ATTACKER)
	if self:data(who)[P.HIT_I] ~= 255 then
		setNext(P.enum_DEFENDER) -- defender might not counter
	end
	if self:doubles(P.enum_ATTACKER) then
		setNext(P.enum_ATTACKER)
	elseif self:doubles(P.enum_DEFENDER) then
		setNext(P.enum_DEFENDER)
	end

	for ev_i = 1, maxEvents do -- loop variable will be lost
		ret.numEvents = ev_i   -- save it here rather than trying to use ret.numEvents as loop var
		local hE = self:hitEvent(index, whos[ev_i])
	
		ret[ev_i] = hE
		index = index + hE.RNsConsumed
		ret.totalRNsConsumed = ret.totalRNsConsumed + hE.RNsConsumed
		
		if (self:isPlayer(whos[ev_i]) and hE.action ~= "DEV") or 
			(not self:isPlayer(whos[ev_i]) and hE.action == "DEV")then 
			ret.eHP = ret.eHP - hE.dmg -- player or enemy-devil damage
		else
			ret.pHP = ret.pHP - hE.dmg -- enemy or self-devil damage
		end
		
		if hE.expGained then 
			ret.expGained = self:expFrom()
			ret.lvlUp = self:willLevel(ret.expGained)
		end
		
		-- make lowercase if enemy action
		if not self:isPlayer(whos[ev_i]) then
			ret[ev_i].action = string.lower(ret[ret.numEvents].action)
		end
		
		if ret.pHP <= 0 then  -- player died, combat over
			ret.pHP = 0
			ret.expGained = 0
			ret.lvlUp = false
			return ret
		end
		
		if ret.eHP <= 0 then  -- enemy died, combat over
			ret.eHP = 0
			ret.expGained = self:expFrom(true, hE.silenced)
			ret.lvlUp = self:willLevel(ret.expGained)
			return ret
		end
	end	
	return ret
end

function P.hitSeq_string(hitSq)
	local hitString = ""
	
	for ev_i = 1, hitSq.numEvents do
		hitString = hitString .. hitSq[ev_i].action .. " "
	end
	
	hitString = hitString .. hitSq.expGained .. "xp"
	if hitSq.lvlUp then hitString = hitString .. " Lvl" end	
	return hitString
end

function P.combatObj:RNsConsumedAt(index)
	return self:hitSeq(index).totalRNsConsumed
end

P.currBattleParams = combat.combatObj:new()

return combat
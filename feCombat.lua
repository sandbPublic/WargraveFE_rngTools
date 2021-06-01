-- Enemy phase behavior no longer supported.
-- Value provided doesn't justify maintaining feature,
-- as enemy phase events can't be permuted and the burns are unpredictable.
-- Instead implement rn advancing to enable fast enemy phase trials.
-- Therefore attacker is always the player.

-- note that staff hit only updates in animation, not in preview
-- in preview, p/e crit and p hit are set to 255 as well
-- therefore, normal combat can be set in preview or after RNs used
-- staff can only be set after RN used

require("feUnitData")

local P = {}
combat = P




local ATTACKER = true
local DEFENDER = false
local PLAYER = true
local ENEMY = false

local BRAVE_S_ID   = {0,0,0,0,0, 07, 11, 11}
local BRAVE_L_ID   = {0,0,0,0,0, 21, 25, 25}
local BRAVE_A_ID   = {0,0,0,0,0, 31, 35, 35}
local BRAVE_B_ID   = {0,0,0,0,0, 44, 49, 50}
local DEVIL_A_ID   = {0,0,0,0,0, 37, 39, 39}
local NOSFERATU_ID = {0,0,0,0,0, 64, 70, 71}
local RUNESWORD_ID = {0,0,0,0,0,125, 17, 17}
local ECLIPSE_ID   = {0,0,0,0,0, 65, 71, 72}
local POISON_S_ID  = {0,0,0,0,0, -1, 08, 08}
local POISON_L_ID  = {0,0,0,0,0, -1, 24, 24}
local POISON_A_ID  = {0,0,0,0,0, 30, 34, 34} -- only poison item in FE6?
local POISON_B_ID  = {0,0,0,0,0, -1, 47, 48}
local POISON_CLAW_ID  = 175 -- FE8 only
local POISON_TALON_ID = 176 -- FE8 only
local STONE_ID        = 181 -- FE8 only
local SILENCE_ID    = {0,0,0,0,0, 75, 80, 81}
local SLEEP_ID      = {0,0,0,0,0, 76, 81, 82}
local BERSERK_ID    = {0,0,0,0,0, 80, 82, 83}

local function weaponIdToType(id)
	if (id == BRAVE_S_ID[GAME_VERSION] 
	 or id == BRAVE_L_ID[GAME_VERSION] 
	 or id == BRAVE_A_ID[GAME_VERSION] 
	 or id == BRAVE_B_ID[GAME_VERSION]) then
		return "brave"
	elseif id == DEVIL_A_ID[GAME_VERSION] then
		return "devil"
	elseif id == NOSFERATU_ID[GAME_VERSION] or id == RUNESWORD_ID[GAME_VERSION] then
		return "drain"
	elseif id == ECLIPSE_ID[GAME_VERSION] then
		return "halve"
	elseif (id == POISON_S_ID[GAME_VERSION] 
		 or id == POISON_L_ID[GAME_VERSION] 
		 or id == POISON_A_ID[GAME_VERSION] 
		 or id == POISON_B_ID[GAME_VERSION]
		 or id == POISON_CLAW_ID
		 or id == POISON_TALON_ID) then
		return "poison"
	elseif id == STONE_ID then
		return "stone"
	elseif id == SILENCE_ID[GAME_VERSION] or id == SLEEP_ID[GAME_VERSION] or id == BERSERK_ID[GAME_VERSION] then
		return "staff"
	end
	
	return "normal"
end

P.ITEM_NAMES = {
	-- FE6
	{
		"Iron Sword",
		"Iron Blade",
		"Steel Sword",
		"Silver Sword",
		"Slim Sword",
		
		"Poison Sword",
		"Brave Sword",
		"Light Brand",
		"Durandal",
		"Armorslayer",
		
		"Rapier",
		"Killing Edge",
		"Lancereaver",
		"Wo Dao",
		"Binding Blade",
		
		"Iron Lance",
		"Steel Lance",
		"Silver Lance",
		"Slim Lance",
		"Poison Lance",	 -- 20
		
		"Brave Lance",
		"Javelin",
		"Maltet",
		"Horseslayer",
		"Killer Lance",
		
		"Axereaver",
		"Iron Axe",
		"Steel Axe",
		"Silver Axe",
		"Poison Axe",
		
		"Brave Axe",
		"Hand Axe",
		"Halberd",
		"Hammer",
		"Devil Axe",
		
		"Swordreaver",
		"Devil Axe", -- 2nd?
		"Halberd", -- 2nd?
		"Iron Bow",
		"Steel Bow", -- 40
		
		"Silver Bow",
		"Poison Bow",
		"Killer Bow",
		"Brave Bow",
		"Short Bow",
		
		"Longbow",
		"Murgleis",
		"Ballista",
		"Long ballista",
		"Killer ballista",
		
		"Fire",
		"Thunder",
		"Fimbulvetr",
		"Elfire",
		"Aircalibur",
		
		"Fenrir",
		"Bolting",
		"Forblaze",
		"Lightning",
		"Divine", -- 60
		
		"Purge",
		"Aureola",
		"Flux",
		"Nosferatu",
		"Eclipse",
		
		"Apocalypse",
		"Heal",
		"Mend",
		"Recover",
		"Physic",
		
		"Fortify",
		"Warp",
		"Rescue",
		"Restore",
		"Silence",
		
		"Sleep",
		"Torch",
		"Hammerne",
		"? Makes closed areas visible",
		"Berserk", -- 80
		
		"Unlock",
		"Barrier",
		"Firestone",
		"Divinestone",
		"But what abo",
		
		"Secret book",
		"Goddess icon",
		"Angelic Robe",
		"Dragonshield",
		"Energy Ring",
		
		"Speedwings",
		"Talisman",
		"Boots",
		"Body ring",
		"Hero crest",
		
		"Knight crest",
		"Orion's bolt",
		"Elysian whip",
		"Guiding ring",
		"Chest key", -- 100
		
		"Door key",
		"?", -- desc crashes
		"Lockpick",
		"Vulnerary",
		"Elixir",
		
		"Pure water",
		"Torch",
		"Antitoxin",
		"Member Card",
		"Silver Card",
		
		"Gold",
		"Dark breath",
		"Eckesachs",
		"Steel blade",
		"Silver blade",
		
		"Al's sword",
		"Gant's lance",
		"Tina's staff",
		"Saint's Staff",
		"Wyrmslayer", -- 120
		
		"White gem",
		"Blue gem",
		"Red gem",
		"Delphi shield",
		"Runesword"
		-- crashes beyond this point
	},
	-- FE7
	{
		"Iron Sword",
		"Slim Sword",
		"Steel Sword",
		"Silver Sword",
		"Iron Blade",
		
		"Steel Blade",
		"Silver Blade",
		"Poison Sword",
		"Rapier",
		"Mani Katti",
		
		"Brave Sword",
		"Wo Dao",
		"Killing Edge",
		"Armorslayer",
		"Wyrmslayer",

		"Light Brand",
		"Runesword",
		"Lancereaver",
		"Longsword",
		"Iron Lance", -- 20
		
		"Slim Lance",
		"Steel Lance",
		"Silver Lance",
		"Poison Lance",
		"Brave Lance",
		
		"Killer Lance",
		"Horseslayer",
		"Javelin",
		"Spear",
		"Axereaver",
		
		"Iron Axe",
		"Steel Axe",
		"Silver Axe",
		"Poison Axe",
		"Brave Axe",
		
		"Killer Axe",
		"Halberd",
		"Hammer",
		"Devil Axe",
		"Hand Axe", -- 40
		
		"Tomahawk",
		"Swordreaver",
		"Swordslayer",
		"Iron Bow",
		"Steel Bow",
		
		"Silver Bow",
		"Poison Bow",
		"Killer Bow",
		"Brave Bow",
		"Short Bow",
		
		"Longbow",
		"Ballista",
		"Iron ballista",
		"Killer ballista",
		"Fire",
		
		"Thunder",
		"Elfire",
		"Bolting",
		"Fimbulvetr",
		"Forblaze", -- 60
		
		"Excalibur",
		"Lightning",
		"Shine",
		"Divine",
		"Purge",
		
		"Aura",
		"Luce",
		"Flux",
		"Luna",
		"Nosferatu",
		
		"Eclipse",
		"Fenrir",
		"Gespenst",
		"Heal",
		"Mend",
		
		"Recover",
		"Physic",
		"Fortify",
		"Restore",
		"Silence", -- 80
		
		"Sleep",
		"Berserk",
		"Warp",
		"Rescue",
		"Torch",
		
		"Hammerne",
		"Unlock",
		"Barrier",
		"Dragon Axe",
		"Angelic robe",
		
		"Energy ring",
		"Secret book",
		"Speedwings",
		"Goddess icon",
		"Dragonshield",
		
		"Talisman",
		"Boots",
		"Body ring",
		"Hero crest",
		"Knight crest", -- 100
		
		"Orion's bolt",
		"Elysian whip",
		"Guiding ring",
		"Chest key",
		"Door key",
		
		"Lockpick",
		"Vulnerary",
		"Elixir",
		"Pure water",
		"Antitoxin",
		
		"Torch",
		"Delphi Shield",
		"Member Card",
		"Silver Card",
		"White gem",
		
		"Blue gem",
		"Red Gem",
		"30 G",
		"Vaida's Spear",
		"Chest key", -- 120
		
		"Mine",
		"Light rune",
		"Iron rune",
		"Filla's Might",
		"Ninis's Grace",
		
		"Thor's Ire",
		"Set's Litany",
		"Emblem blade",
		"Emblem lance",
		"Emblem axe",
		
		"Emblem bow",
		"Durandal",
		"Armads",
		"Aureola",
		"Earth seal",
		
		"Afa's Drops",
		"Heaven seal",
		"Emblem seal",
		"Fell contract",
		"Sol Katti", -- 140
		
		"Wolf Beil",
		"Ereshkigal",
		"Flametongue",
		"Regal blade",
		"Rex Hasta",
		
		"Basilikos",
		"Reinfleche",
		"Heavy spear",
		"Short spear",
		"Ocean seal",
		
		"3000 G",
		"5000 G",
		"Wind Sword",
		"Vulnerary 60",
		"Vulnerary 60",
		
		"Vulnerary 60" -- invalid text from this point
	},
	-- FE8
	{
		"Iron Sword",
		"Slim Sword",
		"Steel Sword",
		"Silver Sword",
		"Iron Blade",
		
		"Steel Blade",
		"Silver Blade",
		"Poison Sword",
		"Rapier",
		"Dummy",
		
		"Brave Sword",
		"Shamshir",
		"Killing Edge",
		"Armorslayer",
		"Wyrmslayer",

		"Light Brand",
		"Runesword",
		"Lancereaver",
		"Zanbato",
		"Iron Lance", -- 20
		
		"Slim Lance",
		"Steel Lance",
		"Silver Lance",
		"Toxin Lance",
		"Brave Lance",
		
		"Killer Lance",
		"Horseslayer",
		"Javelin",
		"Spear",
		"Axereaver",
		
		"Iron Axe",
		"Steel Axe",
		"Silver Axe",
		"Poison Axe",
		"Brave Axe",
		
		"Killer Axe",
		"Halberd",
		"Hammer",
		"Devil Axe",
		"Hand Axe", -- 40
		
		"Tomahawk",
		"Swordreaver",
		"Swordslayer",
		"Hatchet", -- FE8 insert
		"Iron Bow",
		
		"Steel Bow",
		"Silver Bow",
		"Poison Bow",
		"Killer Bow",
		"Brave Bow",
		
		"Short Bow",
		"Long Bow",
		"Ballista",
		"Iron ballista",
		"Killer ballista",
		
		"Fire",
		"Thunder",
		"Elfire",
		"Bolting",
		"Fimbulvetr", -- 60
		
		"Dummy", -- was Forblaze
		"Excalibur",
		"Lightning",
		"Shine",
		"Divine",
		
		"Purge",
		"Aura",
		"Dummy", -- was Luce
		"Flux",
		"Luna",
		
		"Nosferatu",
		"Eclipse",
		"Fenrir",
		"Gleipnir", -- was Gespenst
		"Heal",
		
		"Mend",
		"Recover",
		"Physic",
		"Fortify",
		"Restore", -- 80
		
		"Silence",
		"Sleep",
		"Berserk",
		"Warp",
		"Rescue",
		
		"Torch",
		"Hammerne",
		"Unlock",
		"Barrier",
		"Dragon Axe",
		
		"Angelic robe",
		"Energy ring",
		"Secret book",
		"Speedwings",
		"Goddess icon",
		
		"Dragonshield",
		"Talisman",
		"Swiftsole", -- was Boots
		"Body ring",
		"Hero crest", -- 100
		
		"Knight crest",
		"Orion's bolt",
		"Elysian whip",
		"Guiding ring",
		"Chest key",
		
		"Door key",
		"Lockpick",
		"Vulnerary",
		"Elixir",
		"Pure water",
		
		"Antitoxin",
		"Torch",
		"Delphi Shield",
		"Member Card",
		"Silver Card",
		
		"White gem",
		"Blue gem",
		"Red gem",
		"Gold", -- was Vaida's Spear
		"Reginleif", -- was Chest key -- 120
		
		"Chest key",
		"Dummy",
		"Dummy",
		"Hoplon Guard",
		"Dummy",
		
		"Dummy",
		"Dummy",
		"Dummy",
		"Shadowkiller",
		"Bright Lance",
		
		"Fiendcleaver",
		"Beacon Bow",
		"Seiglinde",
		"Battle Axe",
		"Ivaldi",
		
		"Master seal",
		"Metis's Tome",
		"Dummy",
		"Sharp Claw",
		"Latona", -- 140
		
		"Dragonspear",
		"Vidofnir",
		"Naglfar",
		"Wretched Air",
		"Audhulma",
		
		"Siegmund",
		"Garm",
		"Nidhogg",
		"Heavy spear",
		"Short spear",
		
		"Ocean seal",
		"Lunar Brace",
		"Solar Brace",
		"1 Gold",
		"5 Gold",
		
		"10 Gold",
		"50 Gold",
		"100 Gold",
		"3000 Gold",
		"5000 Gold", -- 160
		
		"Wind Sword",
		"Vulnerary 60",
		"Vulnerary 60",
		"Vulnerary 60",
		"Dance",
		
		"Nightmare",
		"Stone Shard",
		"Demon Light",
		"Ravager",
		"Dragonstone",
		
		"Demon Surge",
		"Shadowshot",
		"Rotten Claw",
		"Fetid Claw",
		"Poison Claw",
		
		"Lethal Talon",
		"Fiery Fang",
		"Hellfang",
		"Evil Eye",
		"Crimson Eye", -- 180
		
		"Stone",
		"Alacalibur",
		"Juna Fruit",
		"150 Gold",
		"200 Gold",
		
		"Black Gem",
		"Gold Gem"
	}
}

P.ITEM_NAMES = P.ITEM_NAMES[GAME_VERSION - 5]
while #P.ITEM_NAMES < 255 do
	table.insert(P.ITEM_NAMES, "Item code too large")
end
P.ITEM_NAMES[0] = "Nothing"

P.ITEM_COLOR_SEGS = {}
while #P.ITEM_COLOR_SEGS < 255 do
	table.insert(P.ITEM_COLOR_SEGS, 
	             {P.ITEM_NAMES[#P.ITEM_COLOR_SEGS + 1]:len(), colorUtil.interpolate((#P.ITEM_COLOR_SEGS/255), colorUtil.chromaticLoop)})
end


P.combatObj = {}

-- non modifying functions

local function hitToString(hit)
	if hit <= 100 then return string.format("%3d", hit) end
	return string.format("%02X", hit)
end

function P.combatObj:toStrings()
	local rStrings = {}
	rStrings[1] = "          LV.XP Hit Crt HP Dmg"
	if self.attacker.weaponType == "staff" then 
		rStrings[1] = "STAFF     LV.XP Hit Crt HP Dmg" 
	end
	
	local function line(combatant)
		local experStr = string.format("%02d", combatant.exp)
		if combatant.exp > 99 then experStr = "--" end
		local doubleStr = "  "
		if combatant.doubles then doubleStr = "x2" end
		
		return string.format("%-10.10s%2d.%s %3s %3s %2d %2d%s %s",
			combatant.name, 
			combatant.level, 
			experStr, 
			hitToString(combatant.hit), 
			hitToString(combatant.crit), 
			combatant.currHP, 
			combatant.dmg,
			doubleStr,
			combatant.weapon)
	end
	
	rStrings[2] = line(self.attacker)
	rStrings[3] = line(self.defender)
	
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
	
	local function line(combatant)
		local rLine = ""
		
		rLine = rLine .. string.format("%2d", combatant.dmg)
		if combatant.doubles then rLine = rLine .. "x2 " 
		else rLine = rLine .. "   " end
		
		if combatant.hit > 100 then rLine = rLine .. " --- "
		elseif combatant.hit == 100 then rLine = rLine .. "100.0"
		else rLine = rLine .. string.format("%05.2f", trueHit(combatant.hit))
		end
		
		if combatant.crit > 100 then rLine = rLine .. " --"
		else rLine = rLine .. string.format(" %2d", combatant.crit)
		end
		
		return rLine
	end
	
	rStrings[2] = line(self.attacker)
	rStrings[3] = line(self.defender)
	
	return rStrings
end

function P.combatObj:willLevel(XPgained)
	return self.player.level ~= 20 and (self.player.exp+XPgained >= 100)
end

--http://serenesforest.net/the-sacred-stones/miscellaneous/calculations/
function P.combatObj:expFrom(didKill, didAssassinate) 
	if self.player.level == 20 then return 0 end
	
	local rExpFrom = self.expFromDmg
	
	if didKill then
		local assassinateMult = 1
		if didAssassinate then assassinateMult = 2 end
		
		rExpFrom = math.min(100, math.floor(self.expFromDmg+
			assassinateMult*math.max(0, self.expFromKill + self.bonusExp)))
	end
	
	if self.player.level == 19 then
		return math.min(math.floor(rExpFrom), 100 - self.player.exp)
	end
	
	return math.floor(rExpFrom)
end

-- string action type, int dmg, int rnsConsumed, bool expWasGained, bool didAssassinate, bool durabilityUsed
function P.combatObj:hitEvent(index, actor)
	local c = self[actor] -- combatant
	
	local retHitEv = {}
	retHitEv.action = ""
	retHitEv.RNsConsumed = 0
	retHitEv.dmg = c.dmg
	
	if c.weaponType == "stone" then
		retHitEv.dmg = 999
	end
	
	-- todo, only matters if eclipse happens after the target is damaged by another unit
	-- prevents doubling. damage unimplemented. in FE6 all but 1 hp
	--if c.weaponType == "halve" then
		--retHitEv.dmg = 999 
	--end
	
	-- assume exp is gained if attacker and player phase, or defender and enemy phase
	-- then falsify
	retHitEv.expWasGained = ((actor == "attacker") == (self.phase == "player"))
	
	retHitEv.didAssassinate = false
	
	local function nextRn()
		retHitEv.RNsConsumed = retHitEv.RNsConsumed + 1
		return rns.rng1:getRN(index+retHitEv.RNsConsumed-1)--use consumed rn
	end
		
	if c.hit ~= 255 then -- no action	
		local willHit = (c.hit > (nextRn()+nextRn())/2)
				
		if classes.hasSureStrike(c.class) then
			if c.level > nextRn() then
				willHit = true
			end
		end
		
		if willHit then
			retHitEv.action = "X"
			retHitEv.durabilityUsed = true
			
			-- confirmed gShield, Pierce, crit, Silencer order
			-- then Devil?
			
			local nonActorClass = self.attacker.class
			if actor == "attacker" then nonActorClass = self.defender.class end
			
			if classes.hasGreatShield(nonActorClass) then
				if c.level > nextRn() then  -- gShield works on actor's level
					retHitEv.action = "G" -- does crit even roll?
					retHitEv.dmg = 0
				end
			end
			
			if classes.hasPierce(c.class) then
				if c.level > nextRn() then
					retHitEv.action = "P"
					retHitEv.dmg = self.attacker.atk
				end
			end
			
			if c.crit > nextRn() then
				local silencerRn = 0
				if GAME_VERSION >= 7 then 
					silencerRn = nextRn() -- does not roll against Demon King
				end
				
				if classes.hasSilencer(c.class) and
					(25 > silencerRn or -- bosses are resistant to silencer
					(50 > silencerRn and self.bonusExp ~= 40)) then
					
					retHitEv.action = "S"
					retHitEv.dmg = 999
					retHitEv.didAssassinate = true
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
			if c.weaponType == "devil" then
				local devilRN = nextRn()
			
				if ((31 - c.luck > devilRN) and (GAME_VERSION >= 7)) or 
					(21 - c.level > devilRN) then
					retHitEv.action = "DEV"
					retHitEv.expWasGained = false -- untested
				end
			end
		else
			retHitEv.action = "O"
			retHitEv.dmg = 0
			retHitEv.expWasGained = false
			retHitEv.durabilityUsed = c.usesMagic
		end
	end
	
	return retHitEv
end

function P.combatObj:staffHitEvent(index)
	local retStvHitEv = {}
	retStvHitEv.action = "STF-X"
	retStvHitEv.RNsConsumed = 1
	retStvHitEv.dmg = 0
	retStvHitEv.expWasGained = (self.phase == "player")
	
	if self.attacker.hit <= rns.rng1:getRN(index) then
		retStvHitEv.action = "STF-O"
		retStvHitEv.expWasGained = false
	end
	
	return retStvHitEv
end

-- variable number of events, 1 to 6
-- X hit events, expGained, lvlUp, totalRNsConsumed, atkHP, defHP
-- can carry enemy's hp from previous combat (technically defenders hp but only relevant on player phase)
-- physical weapons do not consume a use when missing, magic does
-- if a brave weapon consumes last use on first hit, will still do 2nd "brave" hit

-- todo carry more from previous combat? both HP and durability? return durability
function P.combatObj:hitSeq(rnOffset, carriedDefHP)
	local rHitSeq = {} -- numeric keys are hit events
	rHitSeq.expGained = 1
	rHitSeq.lvlUp = false
	rHitSeq.totalRNsConsumed = 0
	
	rHitSeq.attacker = {}
	rHitSeq.attacker.endHP = self.attacker.currHP
	rHitSeq.attacker.endUses = self.attacker.weaponUses
	
	rHitSeq.defender = {}
	rHitSeq.defender.endHP = carriedDefHP or self.defender.currHP
	rHitSeq.defender.endUses = self.defender.weaponUses
	
	local isEnemyPhase = (self.phase == "enemy") -- "other" phase treated as player
	rHitSeq.player = rHitSeq.attacker
	rHitSeq.enemy = rHitSeq.defender
	if isEnemyPhase then
		rHitSeq.enemy = rHitSeq.attacker
		rHitSeq.player = rHitSeq.defender
	end
	
	if rHitSeq.defender.endHP == 0 then
		rHitSeq.expGained = 0
		return rHitSeq
	end
	
	if self.attacker.weaponType == "staff" then
		rHitSeq[1] = self:staffHitEvent(rnOffset)
		rHitSeq.totalRNsConsumed = 1
		return rHitSeq
	end
	
	local nextIsAttacker = true
	
	local terminateCombat = false
	
	local function processNextAttack(actor)
		local hE = self:hitEvent(rnOffset, actor)
		
		rHitSeq[#rHitSeq + 1] = hE
		rnOffset = rnOffset + hE.RNsConsumed
		rHitSeq.totalRNsConsumed = rHitSeq.totalRNsConsumed + hE.RNsConsumed
		
		local nonActor = "attacker"
		if actor == "attacker" then nonActor = "defender" end
		
		-- process damage, due to drain/devil both combatants hp may change
		-- reduce item durability if needed

		if hE.durabilityUsed then
			rHitSeq[actor].endUses = rHitSeq[actor].endUses - 1
		end
	
		if hE.action ~= "DEV" then
			hE.dmg = math.min(hE.dmg, rHitSeq[nonActor].endHP)
			rHitSeq[nonActor].endHP = rHitSeq[nonActor].endHP - hE.dmg
		else
			hE.dmg = math.min(hE.dmg, rHitSeq[actor].endHP)
			rHitSeq[actor].endHP = rHitSeq[actor].endHP - hE.dmg
		end
		
		if self[actor].weaponType == "drain" then
			rHitSeq[actor].endHP = math.min(rHitSeq[actor].endHP + hE.dmg, self[actor].maxHP)
		end
		
		-- lowercase for enemy (attacker on EP, defender on PP)
		if (actor == "attacker") == isEnemyPhase then
			hE.action = hE.action:lower()
		end
		
		if rHitSeq.attacker.endHP < 0 then rHitSeq.attacker.endHP = 0 end
		if rHitSeq.defender.endHP < 0 then rHitSeq.defender.endHP = 0 end
		
		if rHitSeq.enemy.endHP == 0 then
			
			rHitSeq.expGained = self:expFrom(true, hE.didAssassinate)
			rHitSeq.lvlUp = self:willLevel(rHitSeq.expGained)
			terminateCombat = true
			
		elseif rHitSeq.player.endHP == 0 then
		   
			rHitSeq.expGained = 0
			rHitSeq.lvlUp = false
			terminateCombat = true
		
		elseif hE.expWasGained then
		
			rHitSeq.expGained = self:expFrom()
			rHitSeq.lvlUp = self:willLevel(rHitSeq.expGained)
			
		end	
	end
	
	
	processNextAttack("attacker")
	if terminateCombat then return rHitSeq end
	if self.attacker.weaponType == "brave" then
		processNextAttack("attacker")
		if terminateCombat then return rHitSeq end
	end
	
	local defenderCounters = (self.defender.hit ~= 255 and rHitSeq.defender.endUses > 0) -- walls may have hit = 0
	if defenderCounters then
		processNextAttack("defender")
		if terminateCombat then return rHitSeq end
		if self.defender.weaponType == "brave" then
			processNextAttack("defender")
			if terminateCombat then return rHitSeq end
		end
	end
	
	if self.attacker.doubles and rHitSeq.attacker.endUses > 0 then
		processNextAttack("attacker")
		if terminateCombat then return rHitSeq end
		if self.attacker.weaponType == "brave" then
			processNextAttack("attacker")
			if terminateCombat then return rHitSeq end
		end
	elseif self.defender.doubles and defenderCounters and rHitSeq.defender.endUses > 0 then
		processNextAttack("defender")
		if terminateCombat then return rHitSeq end
		if self.defender.weaponType == "brave" then
			processNextAttack("defender")
			if terminateCombat then return rHitSeq end
		end
	end
	
	return rHitSeq
end

function P.hitSeq_string(argHitSeq)
	if not argHitSeq or #argHitSeq < 1 then return "" end

	local hitString = ""
	
	for _, hitEvent in ipairs(argHitSeq) do
		hitString = hitString .. hitEvent.action .. " "
	end
	
	hitString = hitString .. string.format("%2dxp", argHitSeq.expGained)
	if argHitSeq.lvlUp then hitString = hitString .. " Lvl" end
	return hitString
end




-- modifying functions

function P.combatObj:toggleBonusExp()
	self.bonusExp = (self.bonusExp + 20) % 60
	print(string.format("bonus xp: %d", self.bonusExp)) 
end

local function createCombatant(startAddr)
	local c = {}
	
	c.name         = unitData.hexCodeToName(memory.readword(startAddr + addr.NAME_CODE_OFFSET))
	c.class        = classes.HEX_CODES[memory.readword(startAddr + addr.CLASS_CODE_OFFSET)] or classes.OTHER
	c.slot         = memory.readbyte(startAddr + addr.SLOT_ID_OFFSET) -- for carrying hp in multi combats
	
	c.x            = memory.readbyte(startAddr + addr.X_OFFSET)
	c.y            = memory.readbyte(startAddr + addr.Y_OFFSET)

	c.maxHP        = memory.readbyte(startAddr + addr.MAX_HP_OFFSET)
	c.luck         = memory.readbyte(startAddr + addr.MAX_HP_OFFSET + 7)
	c.weaponCode   = memory.readbyte(startAddr + addr.ITEMS_OFFSET)
	c.weapon       = P.ITEM_NAMES[c.weaponCode]
	c.weaponType   = weaponIdToType(c.weaponCode)
	c.weaponUses   = memory.readbyte(startAddr + addr.ITEMS_OFFSET + 1)
	
	for i = 4, 7 do
		if memory.readbyte(startAddr + addr.RANKS_OFFSET + i) > 0 then
			c.usesMagic = true
		end
	end
	
	c.atk          = memory.readbyte(startAddr + addr.ATK_OFFSET)
	c.def          = memory.readbyte(startAddr + addr.DEF_OFFSET)
	c.AS           = memory.readbyte(startAddr + addr.AS_OFFSET)
	c.hit          = memory.readbyte(startAddr + addr.HIT_OFFSET)
	c.crit         = memory.readbyte(startAddr + addr.CRIT_OFFSET)
	c.level        = memory.readbyte(startAddr + addr.LEVEL2_OFFSET)
	c.exp          = memory.readbyte(startAddr + addr.EXP2_OFFSET)
	c.currHP       = memory.readbyte(startAddr + addr.CURR_HP_OFFSET)
	
	return c
end

-- values dependent on both combatants being created, or not member of combatants
function P.combatObj:setNonRAM()
	local speedDifference = self.attacker.AS - self.defender.AS
	self.attacker.doubles = (speedDifference >= 4 and self.attacker.weaponType ~= "halve")
	self.defender.doubles = (speedDifference <= -4 and self.defender.weaponType ~= "halve")	
	
	self.attacker.dmg = math.max(0, self.attacker.atk - self.defender.def)
	self.defender.dmg = math.max(0, self.defender.atk - self.attacker.def)  
	
	self.player = self.attacker
	self.enemy = self.defender
	if self.phase == "enemy" then
		self.player = self.defender
		self.enemy = self.attacker
	end

	local pWeapon = ""
	if self.player.weaponType ~= "normal" then
		pWeapon = " " .. self.player.weaponType:upper()
	end
	local eWeapon = ""
	if self.enemy.weaponType ~= "normal" then
		eWeapon = " " .. self.enemy.weaponType
	end
	
	self.specialWeaponStr = pWeapon .. eWeapon
	if self.phase == "enemy" then
		self.specialWeaponStr = eWeapon .. pWeapon
	end
	
	
	if self.enemy.class == classes.THIEF then
		self.bonusExp = 20
	elseif self.enemy.slot == 129 then -- boss, todo Entombed?
		self.bonusExp = 40
	else
		self.bonusExp = 0
	end
end

-- depends on bonus exp (thief or boss) and assassinates
-- pre-calculate immutable values
function P.combatObj:setExpGain()
	if self.player.level == 20 then
		self.expFromDmg = 0
		self.expFromKill = 0
		return
	end
	
	if self.enemy.class == classes.EGG then
		self.expFromDmg = 0
		self.expFromKill = 50
		return
	end
	
	if self.enemy.slot == 0 then -- snag,wall etc
		self.expFromDmg = 0
		self.expFromKill = 0
		return
	end
	
	plvl = self.player.level
	if classes.PROMOTED[self.player.class] then
		plvl = plvl + 20
	end
	
	elvl = self.enemy.level
	if classes.PROMOTED[self.enemy.class] then
		elvl = elvl + 20
	end
	
	self.expFromDmg = math.max(1,
		(31+elvl-plvl) / classes.EXP_POWER[self.player.class])
	
	local enemyValue = elvl * classes.EXP_POWER[self.enemy.class]
		+classes.EXP_KILL_MODIFIER[self.enemy.class]
		
	local playerValue = plvl * classes.EXP_POWER[self.player.class]
		+classes.EXP_KILL_MODIFIER[self.player.class]
	
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
	-- level 21 Lute killing level 9 cav gains 6, not 22
	
	-- hypothesis: only affects promoted (enemy or player?) or boss units? in FE8?
	if enemyValue - playerValue <= 0 and GAME_VERSION == 7 then
		playerValue = math.floor(playerValue/2)
	end
	
	self.expFromKill = enemyValue - playerValue + 20
end

function P.combatObj:new()
	local o = {}
	setmetatable(o, self)
	self.__index = self
	
	o.attacker = createCombatant(addr.ATTACKER_START)
	o.defender = createCombatant(addr.DEFENDER_START)
	o.phase = addr.getPhase()
	
	o:setNonRAM()
	o:setExpGain()
	
	return o
end

return combat
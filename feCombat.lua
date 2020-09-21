-- Enemy phase behavior no longer supported.
-- Value provided doesn't justify maintaining feature,
-- as enemy phase events can't be permuted and the burns are unpredictable.
-- Instead implement rn advancing to enable fast enemy phase trials.
-- Therefore attacker is always the player.

require("feUnitData")

local P = {}
combat = P




local ATTACKER = true
local DEFENDER = false
local PLAYER = true
local ENEMY = false

-- in the order they appear in RAM
local MAX_HP_I  = 1 -- for drain
local WEAPON_I  = 2 -- weapon code
local ATTACK_I  = 3 -- includes weapon triangle, 0xFF when healing (staff?) or not attacking?
local DEF_I     = 4 -- includes terrain bonus
local AS_I      = 5 -- attack speed
local HIT_I     = 6 -- if can't attack, 0xFF
local LUCK_I    = 7 -- for devil axe in fe7/8
local CRIT_I    = 8 
local LEVEL_I   = 9 -- for Great Shield, Pierce, Sure Strike, and exp cap at level 19
local EXP_I     = 10 -- for level up detection
local HP_I      = 11 -- current HP
local NUM_ADDRS = 11
P.PARAM_NAMES = {"mHP", "wep", "atk", "def", "AS ", "hit", "lck", "crt", "lvl", "exp", "cHP"}
P.PARAM_NAMES.sel_i = AS_I

local ATTACKER_BASE_ADDR = {0x02039200, 0x0203A400, 0x0203A500} 
ATTACKER_BASE_ADDR = ATTACKER_BASE_ADDR[GAME_VERSION - 5]

local DEFENDER_BASE_ADDR = {0x0203927C, 0x0203A480, 0x0203A580} -- FE6 -4 from others
DEFENDER_BASE_ADDR = DEFENDER_BASE_ADDR[GAME_VERSION - 5]

--                            mxHP  weap  atk   def    AS   hit  luck  crit   lvl    xp    hp
--                                   +12 +0x3C    +2    +2    +6    +4    +2  +6/4    +1    +1
local BATTLE_ADDR_OFFSETS = {{0x24, 0x30, 0x6C, 0x6E, 0x70, 0x76, 0x7A, 0x7C, 0x80, 0x81, 0x82},
							 {0x02, 0x0E, 0x4A, 0x4C, 0x4E, 0x54, 0x58, 0x5A, 0x60, 0x61, 0x62},
							 {  -2, 0x0A, 0x46, 0x48, 0x4A, 0x50, 0x54, 0x56, 0x5C, 0x5D, 0x5E}}
BATTLE_ADDR_OFFSETS = BATTLE_ADDR_OFFSETS[GAME_VERSION - 5]

function P.paramInRAM(isAttacker, index)
	index = index or P.PARAM_NAMES.sel_i
	if isAttacker then
		return memory.readbyte(ATTACKER_BASE_ADDR + BATTLE_ADDR_OFFSETS[index])	
	end
	return memory.readbyte(DEFENDER_BASE_ADDR + BATTLE_ADDR_OFFSETS[index])
end

-- note that staff hit only updates in animation, not in preview
-- in preview, p/e crit and p hit are set to 255 as well
-- therefore, normal combat can be set in preview or after RNs used
-- staff can only be set after RN used




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

-- special weapon types
local NORMAL = 1
local BRAVE  = 2
local DEVIL  = 3
local DRAIN  = 4
local HALVE  = 5 -- prevents doubling. damage unimplemented. in FE6 all but 1 hp
local POISON = 6 -- unimplemented, value of opportunity to restore vs minor hp loss
local STONE  = 7 -- treated as 999 dmg

P.WEAPON_TYPE_STRINGS = {"normal", "brave", "devil", "drain", "halve", "poison", "stone"}

local function weaponIdToType(id)
	if (id == BRAVE_S_ID[GAME_VERSION] 
	 or id == BRAVE_L_ID[GAME_VERSION] 
	 or id == BRAVE_A_ID[GAME_VERSION] 
	 or id == BRAVE_B_ID[GAME_VERSION]) then
		return BRAVE
	elseif id == DEVIL_A_ID[GAME_VERSION] then
		return DEVIL
	elseif id == NOSFERATU_ID[GAME_VERSION] or id == RUNESWORD_ID[GAME_VERSION] then
		return DRAIN
	elseif id == ECLIPSE_ID[GAME_VERSION] then
		return HALVE
	elseif (id == POISON_S_ID[GAME_VERSION] 
		 or id == POISON_L_ID[GAME_VERSION] 
		 or id == POISON_A_ID[GAME_VERSION] 
		 or id == POISON_B_ID[GAME_VERSION]
		 or id == POISON_CLAW_ID
		 or id == POISON_TALON_ID) then
		return POISON
	elseif id == STONE_ID then
		return STONE
	end
	
	return NORMAL
end

local WEAPON_CODES = {
	-- FE6, untested
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
		"Poison Lance",	
		-- 20
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
		"Steel Bow",
		-- 40
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
		"Divine",
		-- 60
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
		"Berserk",
		-- 80
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
		"Chest key",
		-- 100
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
		"Tina'd staff",
		"Saint's Staff",
		"Wyrmslayer",
		-- 120
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
		-- 0x10
		"Light Brand",
		"Runesword",
		"Lancereaver",
		"Longsword",
		"Iron Lance",
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
		-- 0x20
		"Steel Axe",
		"Silver Axe",
		"Poison Axe",
		"Brave Axe",
		"Killer Axe",
		"Halberd",
		"Hammer",
		"Devil Axe",
		"Hand Axe",
		"Tomahawk",
		"Swordreaver",
		"Swordslayer",
		"Iron Bow",
		"Steel Bow",
		"Silver Bow",
		"Poison Bow",
		-- 0x30
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
		"Forblaze",
		"Excalibur",
		"Lightning",
		"Shine",
		-- 0x40
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
		-- 0x50
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
		-- 0x60
		"Talisman",
		"Boots",
		"Body ring",
		"Hero crest",
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
		-- 0x70
		"Delphi Shield",
		"Member Card",
		"Silver Card",
		"White gem",
		"Blue gem",
		"Red Gem",
		"30 G",
		"Vaida's Spear",
		"Chest key",
		"Mine",
		"Light rune",
		"Iron rune",
		"Filla's Might",
		"Ninis's Grace",
		"Thor's Ire",
		"Set's Litany",
		-- 0x80
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
		"Sol Katti",
		"Wolf Beil",
		"Ereshkigal",
		"Flametongue",
		-- 0x90
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
		"Dummy", -- was Mani Katti
		"Brave Sword",
		"Shamshir",
		"Killing Edge",
		"Armorslayer",
		"Wyrmslayer",
		-- 0x10
		"Light Brand",
		"Runesword",
		"Lancereaver",
		"Zanbato",
		"Iron Lance",
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
		-- 0x20
		"Steel Axe",
		"Silver Axe",
		"Poison Axe",
		"Brave Axe",
		"Killer Axe",
		"Halberd",
		"Hammer",
		"Devil Axe",
		"Hand Axe",
		"Tomahawk",
		"Swordreaver",
		"Swordslayer",
		"Hatchet", -- FE8 insert
		"Iron Bow",
		"Steel Bow",
		"Silver Bow",
		-- 0x30
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
		"Fimbulvetr",
		"Dummy", -- was Forblaze
		"Excalibur",
		"Lightning",
		-- 0x40
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
		-- 0x50
		"Restore",
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
		-- 0x60
		"Dragonshield",
		"Talisman",
		"Swiftsole", -- was Boots
		"Body ring",
		"Hero crest",
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
		-- 0x70
		"Torch",
		"Delphi Shield",
		"Member Card",
		"Silver Card",
		"White gem",
		"Blue gem",
		"Red gem",
		"Gold", -- was Vaida's Spear
		"Reginleif", -- was Chest key
		"Chest key",
		"Dummy",
		"Dummy",
		"Hoplon Guard",
		"Dummy",
		"Dummy",
		"Dummy",
		-- 0x80
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
		"Latona",
		"Dragonspear",
		"Vidofnir",
		"Naglfar",
		-- 0x90
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
		-- 0xA0
		"5000 Gold",
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
		-- 0xB0
		"Lethal Talon",
		"Fiery Fang",
		"Hellfang",
		"Evil Eye",
		"Crimson Eye",
		"Stone",
		"Alacalibur",
		"Juna Fruit",
		"150 Gold",
		"200 Gold",
		"Black Gem",
		"Gold Gem"
	}
}

WEAPON_CODES = WEAPON_CODES[GAME_VERSION - 5]
while #WEAPON_CODES < 255 do
	table.insert(WEAPON_CODES, "Weapon code too large")
end
WEAPON_CODES[0] = "Nothing"

local UNIT_1_WEAPON_1_ADDR = {0x0202AB94, 0x0202BD6E, 0x0202BE6A}
UNIT_1_WEAPON_1_ADDR = UNIT_1_WEAPON_1_ADDR[GAME_VERSION - 5]
for i = 0, 4 do
	-- memory.writebyte(UNIT_1_WEAPON_1_ADDR+ 2*i, 1+i)
end
function P.nextWeaponSlot1()
	nextByte = (memory.readbyte(UNIT_1_WEAPON_1_ADDR) + 5) % 256
	print()
	for i = 0, 4 do  -- check 5 items at once
		memory.writebyte(UNIT_1_WEAPON_1_ADDR + 2*i, nextByte+i)
		print(string.format("%3d, %s?", nextByte+i, WEAPON_CODES[nextByte+i]))
	end
end




P.combatObj = {}

-- non modifying functions

function P.combatObj:copy()
	local o = {}
	setmetatable(o, self)
	self.__index = self
	
	o.attacker = {}
	o.defender = {}
	for i = 1, NUM_ADDRS do
		o.attacker[i] = self.attacker[i]
		o.defender[i] = self.defender[i]
	end
	o.name = self.name
	
	o.attacker.class  = self.attacker.class
	o.attacker.weapon = self.attacker.weapon
	o.attacker.weaponType = self.attacker.weaponType
	o.defender.class  = self.defender.class
	o.defender.weapon = self.defender.weapon
	o.defender.weaponType = self.defender.weaponType
	
	o.player = o.attacker
	o.enemy = o.defender
	
	o.bonusExp = self.bonusExp
	
	return o
end

function P.combatObj:getHP(isPlayer)
	if isPlayer then return self.player[HP_I] end
	return self.enemy[HP_I]
end

function P.combatObj:getMaxHP(isPlayer)
	if isPlayer then return self.player[MAX_HP_I] end
	return self.enemy[MAX_HP_I]
end

function P.combatObj:isWeaponSpecial(isPlayer)
	if isPlayer then return self.player.weaponType ~= NORMAL end
	return self.enemy.weaponType ~= NORMAL
end

function P.combatObj:data(isAttacker)
	if isAttacker then return self.attacker end
	return self.defender
end

function P.combatObj:isUsingStaff()
	return self.attacker[ATTACK_I] == 0xFF -- healing only?
end

function P.combatObj:dmg(isAttacker, pierce)
	if pierce then
		return self:data(isAttacker)[ATTACK_I]
	end
	return math.max(0, self:data(isAttacker)[ATTACK_I] - self:data(not isAttacker)[DEF_I])
end

function P.combatObj:doubles(isAttacker)
	return (self.attacker[AS_I] >= self.defender[AS_I] + 4 
			and isAttacker and self.attacker.weaponType ~= HALVE) 
		   or 
		   (self.defender[AS_I] >= self.attacker[AS_I] + 4 
		    and not isAttacker and self.defender.weaponType ~= HALVE)
end

local function hitToString(hit)
	if hit <= 100 then return string.format("%3d", hit) end
	return string.format("%02X", hit)
end

function P.combatObj:autoLogLine(isAttacker)
	local d = self:data(isAttacker)

	local function dashIfInvalid(x)
		if x < 100 then return string.format("%2d", x) end
		return "--"
	end
	
	return string.format("lv%2d.%s %2d/%2dhp %sa %2dd %2ds %3sh %2sc %s", 
		d[LEVEL_I], dashIfInvalid(d[EXP_I]), d[MAX_HP_I], d[HP_I], dashIfInvalid(d[ATTACK_I]), d[DEF_I], 
		d[AS_I], hitToString(d[HIT_I]), dashIfInvalid(d[CRIT_I]), WEAPON_CODES[d[WEAPON_I]])
end

function P.combatObj:toStrings()
	local rStrings = {}
	rStrings[1] = "          LV.XP Hit Crt HP Dmg"
	if self:isUsingStaff() then 
		rStrings[1] = "STAFF     LV.XP Hit Crt HP Dmg" 
	end
	
	local function line(isAttacker)
		local name = self.name
		if not isAttacker then name = "Enemy" end
		
		local experStr = string.format("%02d", self:data(isAttacker)[EXP_I])
		if self:data(isAttacker)[EXP_I] > 99 then
			experStr = string.format("--", self:data(isAttacker)[EXP_I])
		end
		
		local rLine = string.format("%-10.10s%2d.%s %3s %3s %2d %2d",
			name, 
			self:data(isAttacker)[LEVEL_I], 
			experStr, 
			hitToString(self:data(isAttacker)[HIT_I]), 
			hitToString(self:data(isAttacker)[CRIT_I]), 
			self:data(isAttacker)[HP_I], 
			self:dmg(isAttacker))
		
		if self:doubles(isAttacker) then rLine = rLine .. "x2 " 
		else rLine = rLine .. "   " end	
		
		rLine = rLine .. WEAPON_CODES[self:data(isAttacker)[WEAPON_I]]
		
		if self:data(isAttacker).weaponType ~= NORMAL then
			rLine = rLine .. " " .. P.WEAPON_TYPE_STRINGS[self:data(isAttacker).weaponType]
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
		
		local hit = self:data(isAttacker)[HIT_I]
		if hit > 100 then rLine = rLine .. " --- "
		elseif hit == 100 then rLine = rLine .. "100.0"
		else rLine = rLine .. string.format("%05.2f", trueHit(hit))
		end
		
		local crit = self:data(isAttacker)[CRIT_I]
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
	return self.player[LEVEL_I] % 20 ~= 0
end

function P.combatObj:willLevel(XPgained)
	return self:canLevel() and (self.player[EXP_I]+XPgained >= 100)
end

function P.combatObj:expFrom(kill, assassinated) --http://serenesforest.net/the-sacred-stones/miscellaneous/calculations/
	if not self:canLevel() then return 0 end
	
	local playerClass = self.player.class
	local playerClassPower = classes.EXP_POWER[playerClass]	
	local expFromDmg = math.max(1,
		(31+self.enemy[LEVEL_I]-self.player[LEVEL_I])/playerClassPower)
	
	local rExpFrom = expFromDmg
	
	if kill then
		-- todo: load enemy class from RAM?
		local enemyClass = self.enemy.class
		local enemyClassPower = classes.EXP_POWER[enemyClass]
		
		local enemyValue = self.enemy[LEVEL_I]*enemyClassPower
			+classes.EXP_KILL_MODIFIER[enemyClass]
		local playerValue = self.player[LEVEL_I]*playerClassPower
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
		-- level 21 Lute killing level 9 cav gains 6, not 22
		
		-- hypothesis: only affects promoted (enemy or player?) or boss units? in FE8?
		if enemyValue - playerValue <= 0 and GAME_VERSION == 7 
			--and self.bonusExp == 40 
			then
			playerValue = math.floor(playerValue/2)
		end
		
		-- eggs always yield 50xp
		
		rExpFrom = math.min(100, math.floor(expFromDmg+assassinateMult*math.max(0, 
			enemyValue-playerValue + 20 + self.bonusExp)))
	end
	
	if self.player[LEVEL_I] % 20 == 19 then
		return math.min(math.floor(rExpFrom), 100 - self.player[EXP_I])
	end
	
	return math.floor(rExpFrom)
end

-- string action type, int dmg, int rnsConsumed, bool expWasGained, bool assassinated
function P.combatObj:hitEvent(index, isAttacker)
	local retHitEv = {}
	retHitEv.action = ""
	retHitEv.RNsConsumed = 0
	retHitEv.dmg = self:dmg(isAttacker)
	
	if self:data(isAttacker).weaponType == STONE then
		retHitEv.dmg = 999
	end
	
	-- todo, only matters if eclipse happens after the target is damaged by another unit
	--if self:data(isAttacker).weaponType == HALVE then
		--retHitEv.dmg = 999 
	--end
	
	retHitEv.expWasGained = isAttacker -- assume true and falsify
	retHitEv.assassinated = false
	
	local hit = self:data(isAttacker)[HIT_I]
	local crt = self:data(isAttacker)[CRIT_I]
	local lvl = self:data(isAttacker)[LEVEL_I]
	
	if lvl > 20 then
		lvl = lvl - 20
	end
	
	local function nextRn()
		retHitEv.RNsConsumed = retHitEv.RNsConsumed + 1
		return rns.rng1:getRN(index+retHitEv.RNsConsumed-1)--use consumed rn
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
				if GAME_VERSION >= 7 then 
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
			if self:data(isAttacker).weaponType == DEVIL then
				local devilRN = nextRn()
			
				if ((31 - self:data(isAttacker)[LUCK_I] > devilRN) and (GAME_VERSION >= 7)) or 
					(21 - self:data(isAttacker)[LEVEL_I] > devilRN) then
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
	
	if self.attacker[HIT_I] <= rns.rng1:getRN(index) then
		retStvHitEv.action = "STF-O"
		retStvHitEv.expWasGained = false
	end
	
	return retStvHitEv
end

-- variable number of events, 1 to 6
-- X hit events, expGained, lvlUp, totalRNsConsumed, pHP, eHP
-- can carry enemy's hp from previous combat
function P.combatObj:hitSeq(rnOffset, carriedEnemyHP)
	local rHitSeq = {} -- numeric keys are hit events
	local isAttackers = {} -- unnecessary to return with current functionality
	rHitSeq.expGained = 1
	rHitSeq.lvlUp = false
	rHitSeq.totalRNsConsumed = 0
	rHitSeq.pHP = self.player[HP_I]
	
	-- pass enemy HP from previous combats this phase if applicable
	rHitSeq.eHP = carriedEnemyHP or self.enemy[HP_I]
	if rHitSeq.eHP == 0 then
		rHitSeq.expGained = 0
		return rHitSeq
	end
	
	if self:isUsingStaff() then
		rHitSeq[1] = self:staffHitEvent(rnOffset)
		isAttackers[1] = true
		rHitSeq.totalRNsConsumed = 1
		return rHitSeq
	end
	
	local function setNext(isAttacker)
		table.insert(isAttackers, isAttacker)
		if self:data(isAttacker).weaponType == BRAVE then
			table.insert(isAttackers, isAttacker)
		end
	end
	
	setNext(ATTACKER)
	defenderCounters = (self.defender[HIT_I] ~= 255)
	
	if defenderCounters then
		setNext(DEFENDER)
	end
	
	if self:doubles(ATTACKER) then
		setNext(ATTACKER)
	elseif self:doubles(DEFENDER) and defenderCounters then
		setNext(DEFENDER)
	end
	
	for ev_i, isAttacker in ipairs(isAttackers) do
		local hE = self:hitEvent(rnOffset, isAttacker)
		
		rHitSeq[ev_i] = hE
		rnOffset = rnOffset + hE.RNsConsumed
		rHitSeq.totalRNsConsumed = rHitSeq.totalRNsConsumed + hE.RNsConsumed
		
		if isAttacker then
			if hE.action ~= "DEV" then
				hE.dmg = math.min(hE.dmg, rHitSeq.eHP)
				rHitSeq.eHP = rHitSeq.eHP - hE.dmg
			else
				hE.dmg = math.min(hE.dmg, rHitSeq.pHP)
				rHitSeq.pHP = rHitSeq.pHP - hE.dmg
			end
			
			if self.attacker.weaponType == DRAIN then
				rHitSeq.pHP = math.min(rHitSeq.pHP + hE.dmg, self.attacker[MAX_HP_I])
			end
			
			if rHitSeq.eHP <= 0 then  -- enemy died, combat over
				rHitSeq.eHP = 0
				rHitSeq.expGained = self:expFrom(true, hE.assassinated)
				rHitSeq.lvlUp = self:willLevel(rHitSeq.expGained)
				return rHitSeq
			elseif hE.expWasGained then -- no kill
				rHitSeq.expGained = self:expFrom()
				rHitSeq.lvlUp = self:willLevel(rHitSeq.expGained)
			end	
		else
			if hE.action ~= "DEV" then
				hE.dmg = math.min(hE.dmg, rHitSeq.pHP)
				rHitSeq.pHP = rHitSeq.pHP - hE.dmg
			else
				hE.dmg = math.min(hE.dmg, rHitSeq.eHP)
				rHitSeq.eHP = rHitSeq.eHP - hE.dmg
			end
			
			if self.defender.weaponType == DRAIN then
				rHitSeq.eHP = math.min(rHitSeq.eHP + hE.dmg, self.defender[MAX_HP_I])
			end

			rHitSeq[ev_i].action = hE.action:lower()
			
			if rHitSeq.pHP <= 0 then  -- player died, combat over
				rHitSeq.pHP = 0
				rHitSeq.expGained = 0
				rHitSeq.lvlUp = false
				return rHitSeq
			end
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

function P.combatObj:RNsConsumedAt(rnOffset)
	return self:hitSeq(rnOffset).totalRNsConsumed
end




-- modifying functions

function P.combatObj:togglePromo(isAttacker)
	self:data(isAttacker)[LEVEL_I] = (self:data(isAttacker)[LEVEL_I] + 19) % 40 + 1
end

function P.combatObj:cycleWeapon(isAttacker)
	self:data(isAttacker).weaponType = self:data(isAttacker).weaponType + 1
	if self:data(isAttacker).weaponType > #P.WEAPON_TYPE_STRINGS then
		self:data(isAttacker).weaponType = 1
	end
	
	print(P.WEAPON_TYPE_STRINGS[self:data(isAttacker).weaponType])
end

function P.combatObj:cycleEnemyClass()
	self.enemy.class = classes.nextRelevantEnemyClass(self.enemy.class)
end

function P.combatObj:toggleBonusExp()
	self.bonusExp = (self.bonusExp + 20) % 60
	print(string.format("bonus xp: %d", self.bonusExp)) 
end

function P.combatObj:new()
	local o = {}
	setmetatable(o, self)
	self.__index = self
	
	o.attacker = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
	o.attacker.weapon = "Nothing"
	o.attacker.weaponType = NORMAL
	o.attacker.class = classes.LORD
	o.name = "no name"
	
	o.defender = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}	
	o.defender.weapon = "Nothing"
	o.defender.weaponType = NORMAL
	o.defender.class = classes.LORD
	
	o.player = o.attacker -- alias, sometimes one description makes more sense
	o.enemy = o.defender
	
	o.bonusExp = 0 -- 20 for killing thief, 40 for killing boss
	
	return o
end

function P.combatObj:set()
	for i = 1, NUM_ADDRS do
		self.attacker[i] = P.paramInRAM(true, i)
		self.defender[i] = P.paramInRAM(false, i)
	end
	
	self.attacker.weapon = WEAPON_CODES[self.attacker[WEAPON_I]]
	self.defender.weapon = WEAPON_CODES[self.defender[WEAPON_I]]
	self.attacker.weaponType = weaponIdToType(self.attacker[WEAPON_I])
	self.defender.weaponType = weaponIdToType(self.defender[WEAPON_I])
	
	self.player.class = selected(unitData.deployedUnits).class
	self.name = selected(unitData.deployedUnits).name
	
	if classes.PROMOTED[self.player.class] then
		self:togglePromo(PLAYER)
	end
	
	self.bonusExp = 0
end




P.currBattleParams = combat.combatObj:new()

return combat
require("feVersion")

local P = {}
classes = P

P.F = {} -- female
P.M = {} -- male

local indexer = 0
local function nextInd()
	indexer = indexer + 1
	return indexer
end

-- TRAINEES
P.M.JOURNEYMAN 		= nextInd()
P.F.RECRUIT 		= nextInd()
P.M.PUPIL 			= nextInd()

-- UNPROMOTED
P.F.LORD 			= nextInd()
P.M.LORD 			= nextInd()

P.F.MAGE 			= nextInd()
P.M.MAGE 			= nextInd()
P.M.MONK 			= nextInd()
P.F.CLERIC 			= nextInd()
P.M.CLERIC 			= nextInd()
P.F.TROUBADOUR 		= nextInd()
P.F.SHAMAN 			= nextInd()
P.M.SHAMAN 			= nextInd()
P.M.MID_PUPIL 		= nextInd()

P.F.WYVERN_RIDER 	= nextInd()
P.M.WYVERN_RIDER 	= nextInd()
P.F.PEGASUS_KNIGHT 	= nextInd()

P.F.CAVALIER 		= nextInd()
P.M.CAVALIER 		= nextInd()
P.F.ARMOR_KNIGHT 	= nextInd()
P.M.ARMOR_KNIGHT 	= nextInd()
P.F.MID_RECRUIT 	= nextInd()

P.M.FIGHTER 		= nextInd()
P.M.BRIGAND 		= nextInd()
P.M.PIRATE 			= nextInd()
P.F.MERCENARY 		= nextInd()
P.M.MERCENARY 		= nextInd()
P.F.NOMAD 			= nextInd()
P.M.NOMAD 			= nextInd()
P.F.ARCHER 			= nextInd()
P.M.ARCHER 			= nextInd()
P.M.MID_JOURNEYMAN 	= nextInd()

P.F.MYRMIDON 		= nextInd()
P.M.MYRMIDON 		= nextInd()
P.F.THIEF 			= nextInd()
P.M.THIEF 			= nextInd()

P.M.TRANSPORTER 	= nextInd()

-- don't give promoted exp
P.F.MANAKETE 		= nextInd() -- enemy manaketes count as promoted?
P.F.DANCER 			= nextInd()
P.M.BARD 			= nextInd()

-- FULLY PROMOTED
P.M.MASTER_LORD 	= nextInd() -- Roy

P.F.BLADE_LORD 		= nextInd() -- Lyndis
P.M.KNIGHT_LORD 	= nextInd() -- Eliwood
P.M.GREAT_LORD7 	= nextInd() -- Hector

P.F.GREAT_LORD 		= nextInd() -- Eirika
P.M.GREAT_LORD8 	= nextInd() -- Ephraim

P.F.WYVERN_LORD 	= nextInd()
P.M.WYVERN_LORD 	= nextInd()
P.F.FALCO_KNIGHT 	= nextInd()
P.F.WYVERN_KNIGHT 	= nextInd()
P.M.WYVERN_KNIGHT 	= nextInd()

P.F.BISHOP 			= nextInd()
P.M.BISHOP 			= nextInd()
P.F.SAGE 			= nextInd()
P.M.SAGE 			= nextInd()
P.F.DRUID 			= nextInd()
P.M.DRUID 			= nextInd()
P.F.VALKYRIE 		= nextInd()
P.F.MAGE_KNIGHT 	= nextInd()
P.M.MAGE_KNIGHT 	= nextInd()
P.M.SUMMONER 		= nextInd()
P.M.S_PUPIL 		= nextInd()

P.F.GENERAL 		= nextInd()
P.M.GENERAL 		= nextInd()
P.F.PALADIN 		= nextInd()
P.M.PALADIN 		= nextInd()
P.F.GREAT_KNIGHT 	= nextInd()
P.M.GREAT_KNIGHT 	= nextInd()
P.F.S_RECRUIT 		= nextInd()

P.M.WARRIOR 		= nextInd()
P.M.BERSERKER 		= nextInd()
P.F.HERO 			= nextInd()
P.M.HERO 			= nextInd()
P.F.RANGER 			= nextInd() -- doubles as nomadic trooper
P.M.RANGER 			= nextInd()
P.F.SNIPER 			= nextInd()
P.M.SNIPER 			= nextInd()
P.M.S_JOURNEYMAN 	= nextInd()

P.F.SWORDMASTER 	= nextInd()
P.M.SWORDMASTER 	= nextInd()
P.F.ASSASSIN 		= nextInd()
P.M.ASSASSIN 		= nextInd()
P.M.ROGUE 			= nextInd()

P.M.ARCHSAGE 		= nextInd()
P.M.NECROMANCER 	= nextInd()


P.EXP_POWER = {}
P.PROMOTED = {}
P.EXP_KILL_MODIFIER = {}
P.CAPS = {}
for class_i = 1, P.M.NECROMANCER do
	P.EXP_POWER[class_i] = 3
	P.PROMOTED[class_i] = (class_i >= P.M.MASTER_LORD)
	P.EXP_KILL_MODIFIER[class_i] = 0
	if not P.PROMOTED[class_i] then
		P.CAPS[class_i] = {60, 20, 20, 20, 20, 20, 30}
	end
end
-- also civilian, Pontifex, entombed
P.EXP_POWER[P.M.JOURNEYMAN] = 1
P.EXP_POWER[P.F.RECRUIT] = 1
P.EXP_POWER[P.M.PUPIL] = 1

-- also soldier, cleric, priest, troubadour
P.EXP_POWER[P.F.MANAKETE] = 2
P.EXP_POWER[P.F.THIEF] = 2
P.EXP_POWER[P.M.THIEF] = 2

-- 5 for fire dragon?

-- units promoted from staff-only, or thieves
P.EXP_KILL_MODIFIER[P.F.BISHOP]   = -20
if version ~= 7 then
	P.EXP_KILL_MODIFIER[P.M.BISHOP]   = -20 -- not in FE7 due to monk but no priest existing
end
P.EXP_KILL_MODIFIER[P.F.VALKYRIE] = -20
P.EXP_KILL_MODIFIER[P.F.ASSASSIN] = -20
P.EXP_KILL_MODIFIER[P.M.ASSASSIN] = -20
P.EXP_KILL_MODIFIER[P.M.ROGUE] 	  = -20

-- exact class doesn't matter, just that they share the desired property
function P.nextRelevantEnemyClass(class)
	if class == P.M.THIEF then		
		print("now bishop, xp kill mod -20")
		return P.F.BISHOP
	elseif class == P.F.BISHOP then
		print("now lord")
		return P.F.LORD
	elseif class == P.F.LORD then
		print("now journeyman, xp power 1")
		return P.M.JOURNEYMAN
	else
		print("now thief, xp power 2")
		return P.M.THIEF
	end
end

-- assume same caps from game to game for now...
P.CAPS[P.F.DANCER]			= {60, 10, 10, 30, 24, 26, 30} -- 78
P.CAPS[P.M.BARD]			= {60, 10, 10, 30, 24, 26, 30}

P.CAPS[P.M.MASTER_LORD]		= {60, 25, 25, 25, 25, 25, 30}

P.CAPS[P.F.BLADE_LORD]		= {60, 24, 29, 30, 22, 22, 30}
P.CAPS[P.M.KNIGHT_LORD]		= {60, 27, 26, 24, 23, 25, 30}
P.CAPS[P.M.GREAT_LORD7]		= {60, 30, 24, 24, 29, 20, 30}

P.CAPS[P.F.GREAT_LORD]		= {60, 24, 29, 30, 22, 25, 30}
P.CAPS[P.M.GREAT_LORD8]		= {60, 27, 26, 24, 23, 23, 30}

P.CAPS[P.F.WYVERN_LORD] 	= {60, 25, 26, 24, 27, 23, 30} -- 78
P.CAPS[P.M.WYVERN_LORD]		= {60, 27, 25, 23, 28, 22, 30} -- 78
P.CAPS[P.F.FALCO_KNIGHT]	= {60, 23, 25, 28, 23, 26, 30}
P.CAPS[P.M.WYVERN_KNIGHT]	= {60, 25, 26, 28, 24, 22, 30}
P.CAPS[P.F.WYVERN_KNIGHT]	= {60, 24, 27, 29, 23, 23, 30}

P.CAPS[P.F.BISHOP]			= {60, 25, 25, 26, 21, 30, 30}
P.CAPS[P.M.BISHOP]			= {60, 25, 26, 24, 22, 30, 30}
P.CAPS[P.F.SAGE]			= {60, 30, 28, 26, 21, 25, 30} -- 78
P.CAPS[P.M.SAGE]			= {60, 28, 30, 26, 21, 25, 30} -- 78
P.CAPS[P.F.DRUID]			= {60, 29, 24, 26, 20, 29, 30}
P.CAPS[P.M.DRUID]			= {60, 29, 26, 26, 21, 28, 30}
P.CAPS[P.F.VALKYRIE]		= {60, 25, 24, 25, 24, 28, 30}
P.CAPS[P.M.SUMMONER]		= {60, 27, 27, 26, 20, 28, 30}
P.CAPS[P.M.S_PUPIL]			= {60, 29, 28, 27, 21, 26, 30}
P.CAPS[P.M.MAGE_KNIGHT]		= {60, 24, 26, 25, 24, 25, 30}
P.CAPS[P.F.MAGE_KNIGHT]		= {60, 25, 24, 25, 24, 28, 30}

P.CAPS[P.F.GENERAL]			= {60, 27, 28, 25, 29, 26, 30} -- 8 none in 7, but different stats?
P.CAPS[P.M.GENERAL]			= {60, 29, 27, 24, 30, 25, 30} -- 78
P.CAPS[P.F.PALADIN]			= {60, 23, 27, 25, 24, 26, 30} -- 78
P.CAPS[P.M.PALADIN]			= {60, 25, 26, 24, 25, 25, 30} -- 78
P.CAPS[P.F.GREAT_KNIGHT]	= {60, 26, 26, 25, 28, 26, 30}
P.CAPS[P.M.GREAT_KNIGHT]	= {60, 28, 24, 24, 29, 25, 30}
P.CAPS[P.F.S_RECRUIT]		= {60, 23, 30, 29, 22, 26, 30}

P.CAPS[P.M.WARRIOR]			= {60, 30, 28, 26, 26, 22, 30}
P.CAPS[P.M.BERSERKER]		= {60, 30, 29, 28, 23, 21, 30}
P.CAPS[P.F.HERO]			= {60, 24, 30, 26, 24, 24, 30} -- 678
P.CAPS[P.M.HERO]			= {60, 25, 30, 26, 25, 22, 30} -- 678
P.CAPS[P.F.RANGER]			= {60, 23, 28, 30, 22, 25, 30} -- 678
P.CAPS[P.M.RANGER]			= {60, 25, 28, 30, 24, 23, 30} -- -78
P.CAPS[P.F.SNIPER]			= {60, 24, 30, 29, 24, 24, 30} -- -78
P.CAPS[P.M.SNIPER]			= {60, 25, 30, 28, 25, 23, 30} -- -78
if version == 6 then 
	P.CAPS[P.M.RANGER][5] = 23 
	P.CAPS[P.F.SNIPER][2] = 23
end

P.CAPS[P.M.S_JOURNEYMAN]	= {60, 26, 29, 28, 23, 23, 30}

P.CAPS[P.F.SWORDMASTER]		= {60, 22, 29, 30, 22, 25, 30} -- 78
P.CAPS[P.M.SWORDMASTER]		= {60, 24, 29, 30, 22, 23, 30} -- 78
P.CAPS[P.F.ASSASSIN]		= {60, 20, 30, 30, 20, 20, 30} -- 78
P.CAPS[P.M.ASSASSIN]		= {60, 20, 30, 30, 20, 20, 30} -- 78
P.CAPS[P.M.ROGUE]			= {60, 20, 30, 30, 20, 20, 30}

P.CAPS[P.M.ARCHSAGE]		= {60, 30, 30, 25, 20, 30, 30}
P.CAPS[P.M.NECROMANCER]		= {60, 30, 25, 25, 30, 30, 30}
-- check other versions

function P.hasSilencer(class)
	return class == P.F.ASSASSIN or class == P.M.ASSASSIN
end

function P.hasPierce(class)
	return class == P.F.WYVERN_KNIGHT or class == P.M.WYVERN_KNIGHT
end

function P.hasSureStrike(class)
	return (class == P.F.SNIPER or class == P.M.SNIPER) and version == 8
end

function P.hasGreatShield(class)
	return (class == P.F.GENERAL or class == P.M.GENERAL) and version == 8
end

return classes
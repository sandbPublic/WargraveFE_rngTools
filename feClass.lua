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

P.F.GREAT_LORD8		= nextInd() -- Eirika
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
P.PROMO_GAINS = {} -- do these vary from game to game?

for class_i = 1, P.M.NECROMANCER do
	P.EXP_POWER[class_i] = 3
	P.PROMOTED[class_i] = (class_i >= P.M.MASTER_LORD)
	P.EXP_KILL_MODIFIER[class_i] = 0
	if not P.PROMOTED[class_i] then
		P.PROMO_GAINS[class_i] = {0, 0, 0, 0, 0, 0, 0,}
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

P.CAPS[P.F.DANCER]			= {60, 10, 10, 30, 24, 26, 30} -- ?78
P.CAPS[P.M.BARD]			= {60, 10, 10, 30, 24, 26, 30}

P.CAPS[P.M.MASTER_LORD]		= {60, 25, 25, 25, 25, 25, 30}

P.CAPS[P.F.BLADE_LORD]		= {60, 24, 29, 30, 22, 22, 30}
P.CAPS[P.M.KNIGHT_LORD]		= {60, 27, 26, 24, 23, 25, 30}
P.CAPS[P.M.GREAT_LORD7]		= {60, 30, 24, 24, 29, 20, 30}

P.CAPS[P.F.GREAT_LORD8]		= {60, 24, 29, 30, 22, 25, 30}
P.CAPS[P.M.GREAT_LORD8]		= {60, 27, 26, 24, 23, 23, 30}

P.CAPS[P.F.WYVERN_LORD] 	= {60, 25, 26, 24, 27, 23, 30} -- 78
							-- 6:  25, 26, 23, 29, 23
P.CAPS[P.M.WYVERN_LORD]		= {60, 27, 25, 23, 28, 22, 30} -- 78
							-- 6:  26, 26, 23, 30, 22
P.CAPS[P.F.FALCO_KNIGHT]	= {60, 23, 25, 28, 23, 26, 30}
							-- 6:  23, 25, 28, 24, 28
P.CAPS[P.M.WYVERN_KNIGHT]	= {60, 25, 26, 28, 24, 22, 30}
P.CAPS[P.F.WYVERN_KNIGHT]	= {60, 24, 27, 29, 23, 23, 30}

P.CAPS[P.F.BISHOP]			= {60, 25, 25, 26, 21, 30, 30}
							-- 6:  26, 25, 26, 21, 30
P.CAPS[P.M.BISHOP]			= {60, 25, 26, 24, 22, 30, 30}
							-- 6:  25, 26, 25, 22, 30
P.CAPS[P.F.SAGE]			= {60, 30, 28, 26, 21, 25, 30} -- 78
							-- 6:  30, 28, 25, 20, 25	
P.CAPS[P.M.SAGE]			= {60, 28, 30, 26, 21, 25, 30} -- 78
							-- 6:  28, 30, 25, 20, 25
P.CAPS[P.F.DRUID]			= {60, 29, 24, 26, 20, 29, 30}
P.CAPS[P.M.DRUID]			= {60, 29, 26, 26, 21, 28, 30}
							-- 6:  29, 24, 26, 21, 28
P.CAPS[P.F.VALKYRIE]		= {60, 25, 24, 25, 24, 28, 30}
							-- 6:  27, 24, 25, 24, 28
P.CAPS[P.M.SUMMONER]		= {60, 27, 27, 26, 20, 28, 30}
P.CAPS[P.M.S_PUPIL]			= {60, 29, 28, 27, 21, 26, 30}
P.CAPS[P.M.MAGE_KNIGHT]		= {60, 24, 26, 25, 24, 25, 30}
P.CAPS[P.F.MAGE_KNIGHT]		= {60, 25, 24, 25, 24, 28, 30}

P.CAPS[P.F.GENERAL]			= {60, 27, 28, 25, 29, 26, 30} -- 8 none in 7, but different stats?
							-- 6:  25, 25, 22, 30, 26
P.CAPS[P.M.GENERAL]			= {60, 29, 27, 24, 30, 25, 30} -- 78
							-- 6:  27, 25, 21, 30, 25
P.CAPS[P.F.PALADIN]			= {60, 23, 27, 25, 24, 26, 30} -- 78 none in 6, but different stats?
P.CAPS[P.M.PALADIN]			= {60, 25, 26, 24, 25, 25, 30} -- 78
							-- 6:  25, 28, 25, 25, 25
P.CAPS[P.F.GREAT_KNIGHT]	= {60, 26, 26, 25, 28, 26, 30} --__8
P.CAPS[P.M.GREAT_KNIGHT]	= {60, 28, 24, 24, 29, 25, 30} --__8
P.CAPS[P.F.S_RECRUIT]		= {60, 23, 30, 29, 22, 26, 30} --__8

P.CAPS[P.M.WARRIOR]			= {60, 30, 28, 26, 26, 22, 30}
							-- 6:  30, 26, 24, 28, 20
P.CAPS[P.M.BERSERKER]		= {60, 30, 29, 28, 23, 21, 30}
							-- 6:  30, 24, 28, 22, 24
P.CAPS[P.F.HERO]			= {60, 24, 30, 26, 24, 24, 30} --678
P.CAPS[P.M.HERO]			= {60, 25, 30, 26, 25, 22, 30} --678
P.CAPS[P.F.RANGER]			= {60, 23, 28, 30, 22, 25, 30} --678
P.CAPS[P.M.RANGER]			= {60, 25, 28, 30, 24, 23, 30} -- 78
							-- 6:  23, 28, 30, 24, 23
P.CAPS[P.F.SNIPER]			= {60, 24, 30, 29, 24, 24, 30} -- 78
							-- 6:  23, 30, 29, 24, 24
P.CAPS[P.M.SNIPER]			= {60, 25, 30, 28, 25, 23, 30} -- 78
							-- 6:  24, 30, 29, 22, 23

P.CAPS[P.M.S_JOURNEYMAN]	= {60, 26, 29, 28, 23, 23, 30} --__8

P.CAPS[P.F.SWORDMASTER]		= {60, 22, 29, 30, 22, 25, 30} --678
P.CAPS[P.M.SWORDMASTER]		= {60, 24, 29, 30, 22, 23, 30} --678
P.CAPS[P.F.ASSASSIN]		= {60, 20, 30, 30, 20, 20, 30} --_78
P.CAPS[P.M.ASSASSIN]		= {60, 20, 30, 30, 20, 20, 30} --_78
P.CAPS[P.M.ROGUE]			= {60, 20, 30, 30, 20, 20, 30} --__8

P.CAPS[P.M.ARCHSAGE]		= {60, 30, 30, 25, 20, 30, 30}
P.CAPS[P.M.NECROMANCER]		= {60, 30, 25, 25, 30, 30, 30}
-- check other versions

P.PROMO_GAINS[P.M.MASTER_LORD] 		= {4, 2, 3, 2, 2, 5, 0}

P.PROMO_GAINS[P.F.BLADE_LORD] 		= {3, 2, 2, 0, 3, 5, 0}
P.PROMO_GAINS[P.M.KNIGHT_LORD] 		= {4, 2, 0, 1, 1, 3, 0}
P.PROMO_GAINS[P.M.GREAT_LORD7] 		= {3, 0, 2, 3, 1, 5, 0}

P.PROMO_GAINS[P.F.GREAT_LORD8] 		= {4, 2, 2, 1, 3, 5, 0}
P.PROMO_GAINS[P.M.GREAT_LORD8] 		= {4, 2, 3, 2, 2, 5, 0}

P.PROMO_GAINS[P.F.WYVERN_LORD] 		= {5, 2, 2, 2, 2, 2, 0} --6__
P.PROMO_GAINS[P.M.WYVERN_LORD] 		= {4, 0, 2, 2, 0, 2, 0} -- 7
							    -- 6:  5, 2, 2, 2, 2, 1
								-- 8:  4, 2, 2, 0, 2, 0
P.PROMO_GAINS[P.F.FALCO_KNIGHT] 	= {5, 2, 0, 0, 2, 2, 0} -- 7
							    -- 6:  6, 2, 2, 2, 2, 2
								-- 8:  5, 2, 0, 2, 2, 2
P.PROMO_GAINS[P.F.WYVERN_KNIGHT]	= {3, 2, 1, 2, 1, 1, 0} --__8
P.PROMO_GAINS[P.M.WYVERN_KNIGHT]	= {3, 1, 2, 3, 0, 1, 0} --__8

P.PROMO_GAINS[P.F.BISHOP] 			= {3, 1, 2, 1, 2, 2, 0} -- 78
							    -- 6:  3, 3, 3, 2, 2, 3
P.PROMO_GAINS[P.M.BISHOP] 			= {3, 2, 1, 0, 3, 2, 0} -- 78
							    -- 6:  3, 3, 3, 2, 2, 3
P.PROMO_GAINS[P.F.SAGE] 			= {3, 1, 1, 0, 3, 3, 0} -- 78
							    -- 6:  3, 3, 3, 3, 1, 2
P.PROMO_GAINS[P.M.SAGE] 			= {4, 1, 0, 0, 3, 3, 0} -- 78
							    -- 6:  4, 4, 2, 1, 2, 2
P.PROMO_GAINS[P.F.DRUID] 			= {2, 4, 2, 3, 2, 2, 0} --6__
P.PROMO_GAINS[P.M.DRUID] 			= {4, 0, 0, 3, 2, 2, 0} -- 78
							    -- 6:  3, 4, 2, 2, 2, 2
P.PROMO_GAINS[P.F.VALKYRIE] 		= {3, 2, 1, 0, 2, 3, 0} -- 78
							    -- 6:  4, 3, 2, 2, 2, 3
P.PROMO_GAINS[P.F.MAGE_KNIGHT] 		= {3, 2, 1, 0, 2, 2, 0} --__8
P.PROMO_GAINS[P.M.MAGE_KNIGHT] 		= {4, 2, 0, 0, 2, 2, 0} --__8
P.PROMO_GAINS[P.M.SUMMONER] 		= {3, 0, 1, 3, 1, 3, 0} --__8
P.PROMO_GAINS[P.M.S_PUPIL] 			= {4, 2, 0, 1, 3, 3, 0} --__8

P.PROMO_GAINS[P.F.GENERAL] 			= {3, 2, 3, 2, 3, 3, 0} -- _8
							    -- 6:  4, 4, 2, 4, 3, 3
P.PROMO_GAINS[P.M.GENERAL] 			= {4, 2, 2, 3, 2, 2, 0} -- 7
							    -- 6:  4, 3, 2, 3, 4, 3
								-- 8:  4, 2, 2, 3, 2, 3
P.PROMO_GAINS[P.F.PALADIN] 			= {1, 1, 1, 2, 1, 2, 0} --__8
P.PROMO_GAINS[P.M.PALADIN] 			= {2, 1, 1, 1, 2, 1, 0} -- 78
							    -- 6:  3, 2, 2, 2, 2, 3 
P.PROMO_GAINS[P.F.GREAT_KNIGHT] 	= {3, 1, 1, 2, 2, 2, 0} --__8
P.PROMO_GAINS[P.M.GREAT_KNIGHT] 	= {3, 2, 1, 2, 2, 1, 0} --__8
P.PROMO_GAINS[P.F.S_RECRUIT] 		= {2, 2, 1, 1, 2, 1, 0} --__8

P.PROMO_GAINS[P.M.WARRIOR] 			= {3, 1, 2, 0, 3, 3, 0} -- 7
							    -- 6:  8, 3, 3, 2, 3, 0
P.PROMO_GAINS[P.M.BERSERKER] 		= {4, 1, 1, 1, 2, 2, 0} -- 7
							    -- 6:  4, 2, 5, 2, 3, 0 brigand
							    -- 6:  5, 3, 4, 1, 3, 0 pirate
P.PROMO_GAINS[P.F.HERO] 			= {6, 3, 5, 5, 4, 3, 0} --6__ but does not exist?
P.PROMO_GAINS[P.M.HERO] 			= {4, 0, 2, 2, 2, 2, 0} -- 7
							    -- 6:  4, 2, 1, 2, 4, 2
P.PROMO_GAINS[P.F.RANGER] 			= {0, 0, 0, 0, 0, 0, 0} --  _8
							    -- 6:  6, 2, 1, 1, 2, 4
P.PROMO_GAINS[P.M.RANGER] 			= {3, 2, 1, 1, 3, 3, 0} -- 7
							    -- 6:  5, 2, 2, 2, 2, 3
P.PROMO_GAINS[P.F.SNIPER] 			= {4, 3, 1, 1, 2, 2, 0} -- 7
							    -- 6:  2, 3, 3, 3, 2, 3
P.PROMO_GAINS[P.M.SNIPER] 			= {3, 1, 2, 2, 2, 3, 0} -- 7
							    -- 6:  3, 3, 3, 2, 2, 2
P.PROMO_GAINS[P.M.S_JOURNEYMAN] 	= {0, 0, 0, 0, 0, 0, 0} -- __8

P.PROMO_GAINS[P.F.SWORDMASTER] 		= {4, 2, 1, 0, 2, 1, 0} -- _8
							    -- 6:  4, 3, 2, 2, 3, 2
P.PROMO_GAINS[P.M.SWORDMASTER] 		= {5, 2, 0, 0, 2, 1, 0} -- 7
							    -- 6:  5, 2, 2, 1, 3, 2
P.PROMO_GAINS[P.F.ASSASSIN] 		= {2, 1, 1, 1, 2, 1, 0} --__8
P.PROMO_GAINS[P.M.ASSASSIN] 		= {3, 1, 0, 0, 2, 2, 0} --_78
P.PROMO_GAINS[P.M.ROGUE] 			= {0, 0, 0, 0, 0, 0, 0} --__8

P.PROMO_GAINS[P.M.ARCHSAGE] 		= {0, 0, 0, 0, 0, 0, 0}
P.PROMO_GAINS[P.M.NECROMANCER] 		= {0, 0, 0, 0, 0, 0, 0}

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
	elseif class == P.M.JOURNEYMAN then
		print("now general, great shield active")
		return P.M.GENERAL
	elseif class == P.M.GENERAL then
		print("now wyvern knight, pierce active")
		return P.M.WYVERN_KNIGHT
	elseif class == P.M.WYVERN_KNIGHT then
		print("now sniper, sure strike active")
		return P.M.SNIPER
	else
		print("now thief, xp power 2")
		return P.M.THIEF
	end
end


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
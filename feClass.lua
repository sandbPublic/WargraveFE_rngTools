local P = {}
classes = P

GAME_VERSION = 6

local indexer = 0
local function nextInd()
	indexer = indexer + 1
	return indexer
end

-- TRAINEES
P.JOURNEYMAN 		= nextInd()
P.RECRUIT 			= nextInd()
P.PUPIL 			= nextInd()

-- UNPROMOTED
P.LORD 				= nextInd()

P.MAGE 				= nextInd()
P.MONK 				= nextInd()
P.CLERIC 			= nextInd()
P.PRIEST 			= nextInd()
P.TROUBADOUR 		= nextInd()
P.SHAMAN 			= nextInd()
P.MID_PUPIL 		= nextInd()

P.WYVERN_RIDER 		= nextInd()
P.PEGASUS_KNIGHT 	= nextInd()

P.CAVALIER 			= nextInd()
P.ARMOR_KNIGHT 		= nextInd()
P.MID_RECRUIT 		= nextInd()

P.FIGHTER 			= nextInd()
P.BRIGAND 			= nextInd()
P.PIRATE 			= nextInd()
P.MERCENARY 		= nextInd()
P.NOMAD 			= nextInd()
P.ARCHER 			= nextInd()
P.MID_JOURNEYMAN 	= nextInd()

P.MYRMIDON 			= nextInd()
P.THIEF 			= nextInd()

P.TRANSPORTER 		= nextInd()

-- don't give promoted exp
P.MANAKETE 			= nextInd() -- enemy manaketes count as promoted?
P.DANCER 			= nextInd()
P.BARD 				= nextInd()

-- FULLY PROMOTED
P.MASTER_LORD 		= nextInd() -- Roy

P.BLADE_LORD 		= nextInd() -- Lyn
P.KNIGHT_LORD 		= nextInd() -- Eliwood
P.GREAT_LORD_7 		= nextInd() -- Hector

P.GREAT_LORD_8_F	= nextInd() -- Eirika
P.GREAT_LORD_8_M 	= nextInd() -- Ephraim

P.WYVERN_LORD_F 	= nextInd()
P.WYVERN_LORD_M 	= nextInd()
P.FALCO_KNIGHT 		= nextInd()
P.WYVERN_KNIGHT_F 	= nextInd()
P.WYVERN_KNIGHT_M 	= nextInd()

P.BISHOP_F 			= nextInd()
P.BISHOP_M 			= nextInd()
P.SAGE_F 			= nextInd()
P.SAGE_M 			= nextInd()
P.DRUID_F 			= nextInd()
P.DRUID_M 			= nextInd()
P.VALKYRIE 			= nextInd()
P.MAGE_KNIGHT_F 	= nextInd()
P.MAGE_KNIGHT_M 	= nextInd()
P.SUMMONER 			= nextInd()
P.S_PUPIL 			= nextInd()

P.PALADIN_F 		= nextInd()
P.PALADIN_M 		= nextInd()
P.GENERAL_F 		= nextInd()
P.GENERAL_M 		= nextInd()
P.GREAT_KNIGHT_F 	= nextInd()
P.GREAT_KNIGHT_M 	= nextInd()
P.S_RECRUIT 		= nextInd()

P.WARRIOR 			= nextInd()
P.BERSERKER 		= nextInd()
P.HERO_F 			= nextInd()
P.HERO_M 			= nextInd()
P.TROOPER_F 		= nextInd() -- doubles as ranger
P.TROOPER_M 		= nextInd()
P.SNIPER_F 			= nextInd()
P.SNIPER_M 			= nextInd()
P.S_JOURNEYMAN 		= nextInd()

P.SWORDMASTER_F 	= nextInd()
P.SWORDMASTER_M 	= nextInd()
P.ASSASSIN_F 		= nextInd()
P.ASSASSIN_M 		= nextInd()
P.ROGUE 			= nextInd()

P.ARCHSAGE 			= nextInd()
P.NECROMANCER 		= nextInd()

P.EXP_POWER = {}
P.PROMOTED = {}
P.EXP_KILL_MODIFIER = {}
P.CAPS = {}
P.PROMO_GAINS = {}

for class_i = 1, P.NECROMANCER do
	P.EXP_POWER[class_i] = 3
	P.PROMOTED[class_i] = (class_i >= P.MASTER_LORD)
	P.EXP_KILL_MODIFIER[class_i] = 0
	if not P.PROMOTED[class_i] then
		P.PROMO_GAINS[class_i] = {0, 0, 0, 0, 0, 0, 0}
		P.CAPS[class_i] = {60, 20, 20, 20, 20, 20, 30}
	end
end
-- also civilian, Pontifex, entombed
P.EXP_POWER[P.JOURNEYMAN] = 1
P.EXP_POWER[P.RECRUIT] = 1
P.EXP_POWER[P.PUPIL] = 1

-- also soldier, cleric, priest, troubadour
P.EXP_POWER[P.MANAKETE] = 2
P.EXP_POWER[P.THIEF] = 2
P.EXP_POWER[P.THIEF] = 2

-- 5 for fire dragon?

-- units promoted from staff-only, or thieves
P.EXP_KILL_MODIFIER[P.BISHOP_F]   = -20
if GAME_VERSION ~= 7 then
	P.EXP_KILL_MODIFIER[P.BISHOP_M]   = -20 -- not in FE7 due to monk but no priest existing
end
P.EXP_KILL_MODIFIER[P.VALKYRIE]   = -20
P.EXP_KILL_MODIFIER[P.ASSASSIN_F] = -20
P.EXP_KILL_MODIFIER[P.ASSASSIN_M] = -20
P.EXP_KILL_MODIFIER[P.ROGUE] 	  = -20

-- https://serenesforest.net/binding-blade/classes/maximum-stats/
-- https://serenesforest.net/blazing-sword/classes/maximum-stats/
-- https://serenesforest.net/the-sacred-stones/classes/maximum-stats/

P.CAPS[P.DANCER]			= {60, 10, 10, 30, 24, 26, 30} -- ?78
P.CAPS[P.BARD]				= {60, 10, 10, 30, 24, 26, 30}

P.CAPS[P.MASTER_LORD]		= {60, 25, 25, 25, 25, 25, 30}
P.CAPS[P.BLADE_LORD]		= {60, 24, 29, 30, 22, 22, 30}
P.CAPS[P.KNIGHT_LORD]		= {60, 27, 26, 24, 23, 25, 30}
P.CAPS[P.GREAT_LORD_7]		= {60, 30, 24, 24, 29, 20, 30}
P.CAPS[P.GREAT_LORD_8_F]	= {60, 24, 29, 30, 22, 25, 30}
P.CAPS[P.GREAT_LORD_8_M]	= {60, 27, 26, 24, 23, 23, 30}

P.CAPS[P.WYVERN_LORD_F] 	= {60, 25, 26, 24, 27, 23, 30}
P.CAPS[P.WYVERN_LORD_M]		= {60, 27, 25, 23, 28, 22, 30}
P.CAPS[P.FALCO_KNIGHT]		= {60, 23, 25, 28, 23, 26, 30}
P.CAPS[P.WYVERN_KNIGHT_M]	= {60, 25, 26, 28, 24, 22, 30}
P.CAPS[P.WYVERN_KNIGHT_F]	= {60, 24, 27, 29, 23, 23, 30}

P.CAPS[P.BISHOP_F]			= {60, 25, 25, 26, 21, 30, 30}
P.CAPS[P.BISHOP_M]			= {60, 25, 26, 24, 22, 30, 30}
P.CAPS[P.SAGE_F]			= {60, 30, 28, 26, 21, 25, 30}
P.CAPS[P.SAGE_M]			= {60, 28, 30, 26, 21, 25, 30}
P.CAPS[P.DRUID_F]			= {60, 29, 24, 26, 20, 29, 30}
P.CAPS[P.DRUID_M]			= {60, 29, 26, 26, 21, 28, 30}
P.CAPS[P.VALKYRIE]			= {60, 25, 24, 25, 24, 28, 30}
P.CAPS[P.SUMMONER]			= {60, 27, 27, 26, 20, 28, 30}
P.CAPS[P.S_PUPIL]			= {60, 29, 28, 27, 21, 26, 30}
P.CAPS[P.MAGE_KNIGHT_F]		= {60, 24, 26, 25, 24, 25, 30}
P.CAPS[P.MAGE_KNIGHT_M]		= {60, 25, 24, 25, 24, 28, 30}

P.CAPS[P.GENERAL_F]			= {60, 27, 28, 25, 29, 26, 30}
P.CAPS[P.GENERAL_M]			= {60, 29, 27, 24, 30, 25, 30}
P.CAPS[P.PALADIN_F]			= {60, 23, 27, 25, 24, 26, 30}
P.CAPS[P.PALADIN_M]			= {60, 25, 26, 24, 25, 25, 30}
P.CAPS[P.GREAT_KNIGHT_F]	= {60, 26, 26, 25, 28, 26, 30}
P.CAPS[P.GREAT_KNIGHT_M]	= {60, 28, 24, 24, 29, 25, 30}
P.CAPS[P.S_RECRUIT]			= {60, 23, 30, 29, 22, 26, 30}

P.CAPS[P.WARRIOR]			= {60, 30, 28, 26, 26, 22, 30}
P.CAPS[P.BERSERKER]			= {60, 30, 29, 28, 23, 21, 30}
P.CAPS[P.HERO_F]			= {60, 24, 30, 26, 24, 24, 30} 
P.CAPS[P.HERO_M]			= {60, 25, 30, 26, 25, 22, 30}
P.CAPS[P.TROOPER_F]			= {60, 23, 28, 30, 22, 25, 30}
P.CAPS[P.TROOPER_M]			= {60, 25, 28, 30, 24, 23, 30}
P.CAPS[P.SNIPER_F]			= {60, 24, 30, 29, 24, 24, 30}
P.CAPS[P.SNIPER_M]			= {60, 25, 30, 28, 25, 23, 30}
P.CAPS[P.S_JOURNEYMAN]		= {60, 26, 29, 28, 23, 23, 30}

P.CAPS[P.SWORDMASTER_F]		= {60, 22, 29, 30, 22, 25, 30}
P.CAPS[P.SWORDMASTER_M]		= {60, 24, 29, 30, 22, 23, 30}
P.CAPS[P.ASSASSIN_F]		= {60, 20, 30, 30, 20, 20, 30}
P.CAPS[P.ASSASSIN_M]		= {60, 20, 30, 30, 20, 20, 30}
P.CAPS[P.ROGUE]				= {60, 20, 30, 30, 20, 20, 30}

P.CAPS[P.ARCHSAGE]			= {60, 30, 30, 25, 20, 30, 30}
P.CAPS[P.NECROMANCER]		= {60, 30, 25, 25, 30, 30, 30}

if GAME_VERSION == 6 then
	P.CAPS[P.WYVERN_LORD_F] = {60, 25, 26, 23, 29, 23, 30}
	P.CAPS[P.WYVERN_LORD_M]	= {60, 26, 26, 23, 30, 22, 30}
	
	P.CAPS[P.FALCO_KNIGHT]	= {60, 23, 25, 28, 24, 28, 30}
	P.CAPS[P.BISHOP_F]		= {60, 26, 25, 26, 21, 30, 30}
	P.CAPS[P.BISHOP_M]		= {60, 25, 26, 25, 22, 30, 30}
	P.CAPS[P.SAGE_F]		= {60, 30, 28, 25, 20, 25, 30}	
	P.CAPS[P.SAGE_M]		= {60, 28, 30, 25, 20, 25, 30}
	P.CAPS[P.DRUID_M]		= {60, 29, 24, 26, 21, 28, 30}
	P.CAPS[P.VALKYRIE]		= {60, 27, 24, 25, 24, 28, 30}
	
	P.CAPS[P.GENERAL_F]		= {60, 25, 25, 22, 30, 26, 30}
	P.CAPS[P.GENERAL_M]		= {60, 27, 25, 21, 30, 25, 30}
	P.CAPS[P.PALADIN_M]		= {60, 25, 28, 25, 25, 25, 30}
	
	P.CAPS[P.WARRIOR]		= {60, 30, 26, 24, 28, 20, 30}
	P.CAPS[P.BERSERKER]		= {60, 30, 24, 28, 22, 24, 30}
	P.CAPS[P.TROOPER_M]		= {60, 23, 28, 30, 24, 23, 30}
	P.CAPS[P.SNIPER_F]		= {60, 23, 30, 29, 24, 24, 30}
	P.CAPS[P.SNIPER_M]		= {60, 24, 30, 29, 22, 23, 30}
end

-- https://serenesforest.net/binding-blade/classes/promotion-gains/
-- https://serenesforest.net/blazing-sword/classes/promotion-gains/
-- https://serenesforest.net/the-sacred-stones/classes/promotion-gains/
-- fe8 promo gains are the same regardless of which class you promote from (except Con and Move)

P.PROMO_GAINS[P.MASTER_LORD] 		= {4, 2, 3, 2, 2, 5, 0}
P.PROMO_GAINS[P.BLADE_LORD] 		= {3, 2, 2, 0, 3, 5, 0}
P.PROMO_GAINS[P.KNIGHT_LORD] 		= {4, 2, 0, 1, 1, 3, 0}
P.PROMO_GAINS[P.GREAT_LORD_7] 		= {3, 0, 2, 3, 1, 5, 0}
P.PROMO_GAINS[P.GREAT_LORD_8_F] 	= {4, 2, 2, 1, 3, 5, 0}
P.PROMO_GAINS[P.GREAT_LORD_8_M] 	= {4, 2, 3, 2, 2, 5, 0}

P.PROMO_GAINS[P.WYVERN_LORD_M] 		= {4, 0, 2, 2, 0, 2, 0}
P.PROMO_GAINS[P.FALCO_KNIGHT] 		= {5, 2, 0, 0, 2, 2, 0}
P.PROMO_GAINS[P.WYVERN_KNIGHT_F]	= {3, 2, 1, 2, 1, 1, 0}
P.PROMO_GAINS[P.WYVERN_KNIGHT_M]	= {3, 1, 2, 3, 0, 1, 0}

P.PROMO_GAINS[P.BISHOP_F] 			= {3, 1, 2, 1, 2, 2, 0}
P.PROMO_GAINS[P.BISHOP_M] 			= {3, 2, 1, 0, 3, 2, 0}
P.PROMO_GAINS[P.SAGE_F] 			= {3, 1, 1, 0, 3, 3, 0}
P.PROMO_GAINS[P.SAGE_M] 			= {4, 1, 0, 0, 3, 3, 0}
P.PROMO_GAINS[P.DRUID_M] 			= {4, 0, 0, 3, 2, 2, 0}
P.PROMO_GAINS[P.VALKYRIE] 			= {3, 2, 1, 0, 2, 3, 0}
P.PROMO_GAINS[P.MAGE_KNIGHT_F] 		= {3, 2, 1, 0, 2, 2, 0}
P.PROMO_GAINS[P.MAGE_KNIGHT_M] 		= {4, 2, 0, 0, 2, 2, 0}
P.PROMO_GAINS[P.SUMMONER] 			= {3, 0, 1, 3, 1, 3, 0}
P.PROMO_GAINS[P.S_PUPIL] 			= {4, 2, 0, 1, 3, 3, 0}

P.PROMO_GAINS[P.GENERAL_F] 			= {3, 2, 3, 2, 3, 3, 0}
P.PROMO_GAINS[P.GENERAL_M] 			= {4, 2, 2, 3, 2, 2, 0}
P.PROMO_GAINS[P.PALADIN_F] 			= {1, 1, 1, 2, 1, 2, 0}
P.PROMO_GAINS[P.PALADIN_M] 			= {2, 1, 1, 1, 2, 1, 0}
P.PROMO_GAINS[P.GREAT_KNIGHT_F] 	= {3, 1, 1, 2, 2, 2, 0}
P.PROMO_GAINS[P.GREAT_KNIGHT_M] 	= {3, 2, 1, 2, 2, 1, 0}
P.PROMO_GAINS[P.S_RECRUIT] 			= {2, 2, 1, 1, 2, 1, 0}

P.PROMO_GAINS[P.WARRIOR] 			= {3, 1, 2, 0, 3, 3, 0}
P.PROMO_GAINS[P.BERSERKER] 			= {4, 1, 1, 1, 2, 2, 0}

P.PROMO_GAINS[P.HERO_M] 			= {4, 0, 2, 2, 2, 2, 0}
P.PROMO_GAINS[P.TROOPER_F] 			= {2, 2, 2, 1, 3, 3, 0}
P.PROMO_GAINS[P.TROOPER_M] 			= {3, 2, 1, 1, 3, 3, 0}
P.PROMO_GAINS[P.SNIPER_F] 			= {4, 3, 1, 1, 2, 2, 0}
P.PROMO_GAINS[P.SNIPER_M] 			= {3, 1, 2, 2, 2, 3, 0}
P.PROMO_GAINS[P.S_JOURNEYMAN] 		= {4, 1, 2, 2, 2, 2, 0}

P.PROMO_GAINS[P.SWORDMASTER_F] 		= {4, 2, 1, 0, 2, 1, 0}
P.PROMO_GAINS[P.SWORDMASTER_M] 		= {5, 2, 0, 0, 2, 1, 0}
P.PROMO_GAINS[P.ASSASSIN_F] 		= {2, 1, 1, 1, 2, 1, 0}
P.PROMO_GAINS[P.ASSASSIN_M] 		= {3, 1, 0, 0, 2, 2, 0}
P.PROMO_GAINS[P.ROGUE] 				= {2, 1, 1, 0, 2, 2, 0}

if GAME_VERSION == 6 then
	P.PROMO_GAINS[P.WYVERN_LORD_F] 	= {5, 2, 2, 2, 2, 2, 0} -- 6 only
	P.PROMO_GAINS[P.WYVERN_LORD_M] 	= {5, 2, 2, 2, 2, 1, 0}
	P.PROMO_GAINS[P.FALCO_KNIGHT] 	= {6, 2, 2, 2, 2, 2, 0}

	P.PROMO_GAINS[P.BISHOP_F] 		= {3, 3, 3, 2, 2, 3, 0}
	P.PROMO_GAINS[P.BISHOP_M] 		= {3, 3, 3, 2, 2, 3, 0}
	P.PROMO_GAINS[P.SAGE_F] 		= {3, 3, 3, 3, 1, 2, 0}
	P.PROMO_GAINS[P.SAGE_M] 		= {4, 4, 2, 1, 2, 2, 0}
	P.PROMO_GAINS[P.DRUID_F]		= {2, 4, 2, 3, 2, 2, 0} -- 6 only
	P.PROMO_GAINS[P.DRUID_M] 		= {3, 4, 2, 2, 2, 2, 0}
	P.PROMO_GAINS[P.VALKYRIE] 		= {4, 3, 2, 2, 2, 3, 0}

	P.PROMO_GAINS[P.GENERAL_F] 		= {4, 4, 2, 4, 3, 3, 0}
	P.PROMO_GAINS[P.GENERAL_M] 		= {4, 3, 2, 3, 4, 3, 0}
	P.PROMO_GAINS[P.PALADIN_M] 		= {3, 2, 2, 2, 2, 3, 0} 

	P.PROMO_GAINS[P.WARRIOR] 		= {8, 3, 3, 2, 3, 0, 0}
	P.PROMO_GAINS[P.BERSERKER] 		= {4, 2, 5, 2, 3, 0, 0}
							 -- pirate 5, 3, 4, 1, 3, 0, 0}
	P.PROMO_GAINS[P.HERO_M] 		= {4, 2, 1, 2, 4, 2, 0}
	P.PROMO_GAINS[P.TROOPER_F] 		= {6, 2, 1, 1, 2, 4, 0}
	P.PROMO_GAINS[P.TROOPER_M] 		= {5, 2, 2, 2, 2, 3, 0}
	P.PROMO_GAINS[P.SNIPER_F] 		= {2, 3, 3, 3, 2, 3, 0}
	P.PROMO_GAINS[P.SNIPER_M] 		= {3, 3, 3, 2, 2, 2, 0}

	P.PROMO_GAINS[P.SWORDMASTER_F] 	= {4, 3, 2, 2, 3, 2, 0}
	P.PROMO_GAINS[P.SWORDMASTER_M] 	= {5, 2, 2, 1, 3, 2, 0}
end

if GAME_VERSION == 8 then
	P.PROMO_GAINS[P.WYVERN_LORD_M] 		= {4, 2, 2, 0, 2, 0, 0}
	P.PROMO_GAINS[P.FALCO_KNIGHT] 		= {5, 2, 0, 2, 2, 2, 0}

	P.PROMO_GAINS[P.GENERAL_M] 			= {4, 2, 2, 3, 2, 3, 0}

	P.PROMO_GAINS[P.HERO_M] 			= {4, 1, 2, 2, 2, 2, 0}
end

-- exact class doesn't matter, just that they share the desired property
function P.nextRelevantEnemyClass(class)
	if class == P.THIEF then		
		print("now bishop, xp kill mod -20")
		return P.BISHOP_F
	elseif class == P.BISHOP_F then
		print("now lord")
		return P.LORD
	elseif class == P.LORD then
		print("now journeyman, xp power 1")
		return P.JOURNEYMAN
	elseif class == P.JOURNEYMAN then
		print("now general, great shield active")
		return P.GENERAL_M
	elseif class == P.GENERAL_M then
		print("now wyvern knight, pierce active")
		return P.WYVERN_KNIGHT_M
	elseif class == P.WYVERN_KNIGHT_M then
		print("now sniper, sure strike active")
		return P.SNIPER_M
	else
		print("now thief, xp power 2")
		return P.THIEF
	end
end

function P.isNoncombat(class)
	return class == P.DANCER or 
		class == P.BARD or 
		class == P.CLERIC or 
		class == P.PRIEST or 
		class == P.TROUBADOUR or 
		class == P.TRANSPORTER
end

function P.hasSilencer(class)
	return class == P.ASSASSIN_F or class == P.ASSASSIN_M
end

function P.hasPierce(class)
	return class == P.WYVERN_KNIGHT_F or class == P.WYVERN_KNIGHT_M
end

function P.hasSureStrike(class)
	return (class == P.SNIPER_F or class == P.SNIPER_M) and GAME_VERSION == 8
end

function P.hasGreatShield(class)
	return (class == P.GENERAL_F or class == P.GENERAL_M) and GAME_VERSION == 8
end

return classes
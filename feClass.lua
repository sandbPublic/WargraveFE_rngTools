require("feMisc")


local P = {}
classes = P


local indexer = 0
do
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

P.MAGE 				= nextInd() -- 5
P.MONK 				= nextInd()
P.CLERIC 			= nextInd()
P.PRIEST 			= nextInd()
P.TROUBADOUR 		= nextInd()
P.SHAMAN 			= nextInd() -- 10
P.MID_PUPIL 		= nextInd()

P.WYVERN_RIDER 		= nextInd()
P.PEGASUS_KNIGHT 	= nextInd()

P.CAVALIER 			= nextInd()
P.ARMOR_KNIGHT 		= nextInd() -- 15
P.MID_RECRUIT 		= nextInd()

P.FIGHTER 			= nextInd()
P.BRIGAND 			= nextInd()
P.PIRATE 			= nextInd()
P.MERCENARY 		= nextInd() -- 20
P.NOMAD 			= nextInd()
P.ARCHER 			= nextInd()
P.SOLDIER           = nextInd()
P.MID_JOURNEYMAN 	= nextInd()

P.MYRMIDON 			= nextInd() -- 25
P.THIEF 			= nextInd()

P.TRANSPORTER 		= nextInd()

-- don't give promoted exp
P.MANAKETE 			= nextInd() -- enemy manaketes count as promoted?
P.DANCER 			= nextInd()
P.BARD 				= nextInd() -- 30

P.EGG    		    = nextInd() -- special exp properties

P.OTHER 		    = nextInd()

-- FULLY PROMOTED
P.MASTER_LORD 		= nextInd() -- Roy

P.BLADE_LORD 		= nextInd() -- Lyn
P.KNIGHT_LORD 		= nextInd() -- Eliwood
P.GREAT_LORD_7 		= nextInd() -- Hector

P.GREAT_LORD_8_F	= nextInd() -- Eirika
P.GREAT_LORD_8_M 	= nextInd() -- Ephraim

P.WYVERN_LORD_F 	= nextInd()
P.WYVERN_LORD_M 	= nextInd() -- 40
P.FALCO_KNIGHT 		= nextInd()
P.WYVERN_KNIGHT_F 	= nextInd()
P.WYVERN_KNIGHT_M 	= nextInd()

P.BISHOP_F 			= nextInd()
P.BISHOP_M 			= nextInd() -- 45
P.SAGE_F 			= nextInd()
P.SAGE_M 			= nextInd()
P.DRUID_F 			= nextInd()
P.DRUID_M 			= nextInd()
P.VALKYRIE 			= nextInd() -- 50
P.MAGE_KNIGHT_F 	= nextInd()
P.MAGE_KNIGHT_M 	= nextInd()
P.SUMMONER 			= nextInd()
P.S_PUPIL 			= nextInd()

P.PALADIN_F 		= nextInd() -- 55
P.PALADIN_M 		= nextInd()
P.GENERAL_F 		= nextInd()
P.GENERAL_M 		= nextInd()
P.GREAT_KNIGHT_F 	= nextInd()
P.GREAT_KNIGHT_M 	= nextInd() -- 60
P.S_RECRUIT 		= nextInd()

P.WARRIOR 			= nextInd()
P.BERSERKER 		= nextInd()
P.HERO_F 			= nextInd()
P.HERO_M 			= nextInd() -- 65
P.TROOPER_F 		= nextInd() -- doubles as ranger
P.TROOPER_M 		= nextInd()
P.SNIPER_F 			= nextInd()
P.SNIPER_M 			= nextInd()
P.S_JOURNEYMAN 		= nextInd() -- 70

P.SWORDMASTER_F 	= nextInd()
P.SWORDMASTER_M 	= nextInd()
P.ASSASSIN_F 		= nextInd()
P.ASSASSIN_M 		= nextInd()
P.ROGUE 			= nextInd() -- 75

P.TRANSPO_PROMO		= nextInd()

P.ARCHSAGE 			= nextInd()
P.NECROMANCER 		= nextInd()

P.ENTOMBED          = nextInd()
P.OTHER_PROMOTED    = nextInd() -- 80
end

P.NAMES = {
"Journeyman",
"Recruit",
"Pupil",
"Lord",
"Mage",
"Monk",
"Cleric",
"Priest",
"Troubadour",
"Shaman",
"Mid_Pupil",
"Wyvern_Rider",
"Pegasus_Knight",
"Cavalier",
"Armor_Knight",
"Mid_Recruit",
"Fighter",
"Brigand",
"Pirate",
"Mercenary",
"Nomad",
"Archer",
"Soldier",
"Mid_Journeyman",
"Myrmidon",
"Thief",
"Transporter",
"Manakete",
"Dancer",
"Bard",
"Egg",
"Other",
"Master_Lord",
"Blade_Lord",
"Knight_Lord",
"Great_Lord_7",
"Great_Lord_8_F",
"Great_Lord_8_M",
"Wyvern_Lord_F",
"Wyvern_Lord_M",
"Falco_Knight",
"Wyvern_Knight_F",
"Wyvern_Knight_M",
"Bishop_F",
"Bishop_M",
"Sage_F",
"Sage_M",
"Druid_F",
"Druid_M",
"Valkyrie",
"Mage_Knight_F",
"Mage_Knight_M",
"Summoner",
"S_Pupil",
"Paladin_F",
"Paladin_M",
"General_F ",
"General_M",
"Great_Knight_F",
"Great_Knight_M",
"S_Recruit",
"Warrior",
"Berserker",
"Hero_F",
"Hero_M ",
"Trooper_F",
"Trooper_M",
"Sniper_F",
"Sniper_M",
"S_Journeyman",
"Swordmaster_F",
"Swordmaster_M ",
"Assassin_F",
"Assassin_M",
"Rogue",
"Transpo_Promo",
"Archsage",
"Necromancer",
"Entombed",
"Other_Promoted"
}

-- todo inanimate classes eg wall, snag

P.EXP_POWER = {}
P.PROMOTED = {}
P.EXP_KILL_MODIFIER = {}
P.CAPS = {}
P.PROMO_GAINS = {}
P.HEX_CODES = {}

for class_i = 1, indexer do
	P.EXP_POWER[class_i] = 3
	P.PROMOTED[class_i] = (class_i >= P.MASTER_LORD)
	P.EXP_KILL_MODIFIER[class_i] = 0
	
	-- only apply for unpromoted, but will be overwritten later
	P.PROMO_GAINS[class_i] = {0, 0, 0, 0, 0, 0, 0}
	P.CAPS[class_i] = {60, 20, 20, 20, 20, 20, 30}
end

-- also civilian, Pontifex
P.EXP_POWER[P.JOURNEYMAN] = 1
P.EXP_POWER[P.RECRUIT] = 1
P.EXP_POWER[P.PUPIL] = 1
P.EXP_POWER[P.ENTOMBED] = 1

P.EXP_POWER[P.CLERIC] = 2
P.EXP_POWER[P.PRIEST] = 2
P.EXP_POWER[P.TROUBADOUR] = 2
P.EXP_POWER[P.THIEF] = 2
P.EXP_POWER[P.THIEF] = 2
P.EXP_POWER[P.SOLDIER] = 2
P.EXP_POWER[P.MANAKETE] = 2

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

do -- CAPS
P.CAPS[P.DANCER]			= {60, 10, 10, 30, 24, 26, 30}
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
P.CAPS[P.MAGE_KNIGHT_F]		= {60, 25, 24, 25, 24, 28, 30}
P.CAPS[P.MAGE_KNIGHT_M]		= {60, 24, 26, 25, 24, 25, 30}

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
	P.CAPS[P.DANCER]		= {60, 20, 20, 20, 20, 20, 30}
	P.CAPS[P.BARD]			= {60, 20, 20, 20, 20, 20, 30}

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
end


-- https://serenesforest.net/binding-blade/classes/promotion-gains/
-- https://serenesforest.net/blazing-sword/classes/promotion-gains/
-- https://serenesforest.net/the-sacred-stones/classes/promotion-gains/
-- fe8 promo gains are the same regardless of which class you promote from (except Con and Move)

do -- PROMO_GAINS
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

P.PROMO_GAINS[P.TRANSPO_PROMO]      = {0, 0, 0, 0, 0, 0, 0} -- untested

P.PROMO_GAINS[P.ENTOMBED]           = {0, 0, 0, 0, 0, 0, 0} -- untested

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
end

-- HEX_CODES, duplicate unpromoted are male, female
if GAME_VERSION == 6 then
	P.HEXCODES[0xA130] = P.LORD
	P.HEXCODES[0xA178] = P.MERCENARY
	P.HEXCODES[0xA1C0] = P.MERCENARY
	P.HEXCODES[0xA208] = P.HERO_M
	P.HEXCODES[0xA250] = P.HERO_F
	P.HEXCODES[0xA298] = P.MYRMIDON
	P.HEXCODES[0xA2E0] = P.MYRMIDON
	P.HEXCODES[0xA328] = P.SWORDMASTER_M
	P.HEXCODES[0xA370] = P.SWORDMASTER_F
	P.HEXCODES[0xA3B8] = P.FIGHTER
	P.HEXCODES[0xA400] = P.WARRIOR
	P.HEXCODES[0xA448] = P.ARMOR_KNIGHT
	P.HEXCODES[0xA490] = P.ARMOR_KNIGHT
	P.HEXCODES[0xA4D8] = P.GENERAL_M
	P.HEXCODES[0xA520] = P.GENERAL_F
	P.HEXCODES[0xA568] = P.ARCHER
	P.HEXCODES[0xA5B0] = P.ARCHER
	P.HEXCODES[0xA5F8] = P.SNIPER_M
	P.HEXCODES[0xA640] = P.SNIPER_F
	P.HEXCODES[0xA688] = P.PRIEST
	P.HEXCODES[0xA6D0] = P.CLERIC
	P.HEXCODES[0xA718] = P.BISHOP_M
	P.HEXCODES[0xA760] = P.BISHOP_F
	P.HEXCODES[0xA7A8] = P.MAGE
	P.HEXCODES[0xA7F0] = P.MAGE
	P.HEXCODES[0xA838] = P.SAGE_M
	P.HEXCODES[0xA880] = P.SAGE_F
	P.HEXCODES[0xA8C8] = P.SHAMAN
	P.HEXCODES[0xA910] = P.SHAMAN
	P.HEXCODES[0xA958] = P.DRUID_M
	P.HEXCODES[0xA9A0] = P.DRUID_F
	P.HEXCODES[0xA9E8] = P.CAVALIER
	P.HEXCODES[0xAA30] = P.CAVALIER
	P.HEXCODES[0xAA78] = P.PALADIN_M
	P.HEXCODES[0xAAC0] = P.PALADIN_F
	P.HEXCODES[0xAB08] = P.TROUBADOUR
	P.HEXCODES[0xAB50] = P.VALKYRIE
	P.HEXCODES[0xAB98] = P.NOMAD
	P.HEXCODES[0xABE0] = P.NOMAD
	P.HEXCODES[0xAC28] = P.TROOPER_M
	P.HEXCODES[0xAC70] = P.TROOPER_F
	P.HEXCODES[0xACB8] = P.PEGASUS_KNIGHT
	P.HEXCODES[0xAD00] = P.FALCO_KNIGHT
	P.HEXCODES[0xAD48] = P.WYVERN_RIDER
	P.HEXCODES[0xAD90] = P.WYVERN_RIDER
	P.HEXCODES[0xADD8] = P.WYVERN_LORD_M
	P.HEXCODES[0xAE20] = P.WYVERN_LORD_F
	P.HEXCODES[0xAE68] = P.SOLDIER
	P.HEXCODES[0xAEB0] = P.BANDIT
	P.HEXCODES[0xAEF8] = P.PIRATE
	P.HEXCODES[0xAF40] = P.BERSERKER
	P.HEXCODES[0xAF88] = P.THIEF
	P.HEXCODES[0xAFD0] = P.THIEF
	P.HEXCODES[0xB018] = P.BARD
	P.HEXCODES[0xB060] = P.DANCER
	P.HEXCODES[0xB0A8] = P.MANAKETE
	P.HEXCODES[0xB0F0] = P.MANAKETE
	P.HEXCODES[0xB180] = P.OTHER -- Divine Dragon, Fa??
	P.HEXCODES[0xB1C8] = P.OTHER -- Dark Dragon
	P.HEXCODES[0xB210] = P.OTHER -- King
	P.HEXCODES[0xB258] = P.OTHER -- Citizen M
	P.HEXCODES[0xB2A0] = P.OTHER -- Citizen F
	P.HEXCODES[0xB2E8] = P.OTHER -- Children M
	P.HEXCODES[0xB330] = P.OTHER -- Children F
	P.HEXCODES[0xB378] = P.TRANSPORTER
	P.HEXCODES[0xB3C0] = P.MASTER_LORD
end

if GAME_VERSION == 7 then
	P.HEX_CODES[0x01B0] = P.LORD -- Lord (Eliwood)
	P.HEX_CODES[0x0204] = P.LORD -- Lord (Lyn)
	P.HEX_CODES[0x0258] = P.LORD -- Lord (Hector)
	P.HEX_CODES[0x03A8] = P.KNIGHT_LORD
	P.HEX_CODES[0x03FC] = P.BLADE_LORD
	P.HEX_CODES[0x0450] = P.GREAT_LORD_7
	P.HEX_CODES[0x04A4] = P.MERCENARY
	P.HEX_CODES[0x04F8] = P.MERCENARY -- Mercenary (from FE6?)*
	P.HEX_CODES[0x054C] = P.HERO_M
	P.HEX_CODES[0x05A0] = P.HERO_F
	P.HEX_CODES[0x05F4] = P.MYRMIDON
	P.HEX_CODES[0x0648] = P.MYRMIDON
	P.HEX_CODES[0x069C] = P.SWORDMASTER_M
	P.HEX_CODES[0x06F0] = P.SWORDMASTER_F
	P.HEX_CODES[0x0744] = P.FIGHTER
	P.HEX_CODES[0x0798] = P.WARRIOR
	P.HEX_CODES[0x07EC] = P.ARMOR_KNIGHT
	P.HEX_CODES[0x0840] = P.ARMOR_KNIGHT
	P.HEX_CODES[0x0894] = P.GENERAL_M
	P.HEX_CODES[0x08E8] = P.GENERAL_F
	P.HEX_CODES[0x093C] = P.ARCHER
	P.HEX_CODES[0x0990] = P.ARCHER
	P.HEX_CODES[0x09E4] = P.SNIPER_M
	P.HEX_CODES[0x0A38] = P.SNIPER_F
	P.HEX_CODES[0x0A8C] = P.MONK
	P.HEX_CODES[0x0AE0] = P.CLERIC
	P.HEX_CODES[0x0B34] = P.BISHOP_M
	P.HEX_CODES[0x0B88] = P.BISHOP_F
	P.HEX_CODES[0x0BDC] = P.MAGE
	P.HEX_CODES[0x0C30] = P.MAGE
	P.HEX_CODES[0x0C84] = P.SAGE_M
	P.HEX_CODES[0x0CD8] = P.SAGE_F
	P.HEX_CODES[0x0D2C] = P.SHAMAN
	P.HEX_CODES[0x0D80] = P.SHAMAN
	P.HEX_CODES[0x0DD4] = P.DRUID_M
	P.HEX_CODES[0x0E28] = P.DRUID_F
	P.HEX_CODES[0x0E7C] = P.CAVALIER
	P.HEX_CODES[0x0ED0] = P.CAVALIER
	P.HEX_CODES[0x0F24] = P.PALADIN_M
	P.HEX_CODES[0x0F78] = P.PALADIN_F
	P.HEX_CODES[0x0FCC] = P.TROUBADOUR
	P.HEX_CODES[0x1020] = P.VALKYRIE
	P.HEX_CODES[0x1074] = P.NOMAD
	P.HEX_CODES[0x10C8] = P.NOMAD
	P.HEX_CODES[0x111C] = P.TROOPER_M
	P.HEX_CODES[0x1170] = P.TROOPER_F
	P.HEX_CODES[0x11C4] = P.PEGASUS_KNIGHT
	P.HEX_CODES[0x1218] = P.FALCO_KNIGHT
	P.HEX_CODES[0x126C] = P.WYVERN_RIDER
	P.HEX_CODES[0x12C0] = P.WYVERN_RIDER
	P.HEX_CODES[0x1314] = P.WYVERN_LORD_M
	P.HEX_CODES[0x1368] = P.WYVERN_LORD_F
	P.HEX_CODES[0x13BC] = P.SOLDIER
	P.HEX_CODES[0x1410] = P.BRIGAND
	P.HEX_CODES[0x1464] = P.PIRATE
	P.HEX_CODES[0x14B8] = P.BERSERKER
	P.HEX_CODES[0x150C] = P.THIEF
	P.HEX_CODES[0x1560] = P.THIEF
	P.HEX_CODES[0x15B4] = P.ASSASSIN_M
	P.HEX_CODES[0x1608] = P.OTHER -- Dead Civilian*
	P.HEX_CODES[0x165C] = P.DANCER
	P.HEX_CODES[0x16B0] = P.BARD
	P.HEX_CODES[0x1704] = P.ARCHSAGE
	P.HEX_CODES[0x1758] = P.OTHER -- Magic Seal
	P.HEX_CODES[0x17AC] = P.TRANSPORTER -- Tent
	P.HEX_CODES[0x1800] = P.OTHER -- Dark Druid
	P.HEX_CODES[0x1854] = P.OTHER -- Fire Dragon
	P.HEX_CODES[0x18A8] = P.OTHER -- Male Civilian*
	P.HEX_CODES[0x18FC] = P.OTHER -- Female Civilian*
	P.HEX_CODES[0x1950] = P.OTHER -- Nils (keeled over)*
	P.HEX_CODES[0x19A4] = P.OTHER -- Bramimond
	P.HEX_CODES[0x19F8] = P.OTHER -- Male Peer*
	P.HEX_CODES[0x1A4C] = P.OTHER -- Female Peer*
	P.HEX_CODES[0x1AA0] = P.OTHER -- Prince*
	P.HEX_CODES[0x1AF4] = P.OTHER -- Queen*
	P.HEX_CODES[0x1B48] = P.OTHER -- Civilian*
	P.HEX_CODES[0x1B9C] = P.OTHER -- Corsair
	P.HEX_CODES[0x1BF0] = P.OTHER -- Prince (front of Tactician?)*
	P.HEX_CODES[0x1C44] = P.OTHER -- Prince (Tactician lying down?)*
	P.HEX_CODES[0x1C98] = P.OTHER -- Prince (back of Tactician?)*
	P.HEX_CODES[0x1CEC] = P.OTHER -- Child (back of Dancer)*
	P.HEX_CODES[0x1D40] = P.OTHER -- Fire Dragon (Ninian wounded)*
	P.HEX_CODES[0x1D94] = P.OTHER -- Dead Warrior*
	P.HEX_CODES[0x1DE8] = P.OTHER -- Male Child*
	P.HEX_CODES[0x1E3C] = P.OTHER -- Female Child*
	P.HEX_CODES[0x1E90] = P.TRANSPO_PROMO -- Transporter (Cart)
	P.HEX_CODES[0x1EE4] = P.SAGE_F -- Female Sage (Limstella)*
	P.HEX_CODES[0x1F38] = P.ARCHER -- Archer riding Ballista*
	P.HEX_CODES[0x1F8C] = P.ARCHER -- Archer riding Iron Ballista*
	P.HEX_CODES[0x1FE0] = P.ARCHER -- Archer riding Killer Ballista*
	P.HEX_CODES[0x2034] = P.OTHER -- Empty Ballista*
	P.HEX_CODES[0x2088] = P.OTHER -- Empty Iron Ballista*
	P.HEX_CODES[0x20DC] = P.OTHER -- Empty Killer Ballista*
end

if GAME_VERSION == 8 then
P.HEX_CODES[0x7164] = P.LORD
P.HEX_CODES[0x71B8] = P.LORD
P.HEX_CODES[0x720C] = P.GREAT_LORD_8_M
P.HEX_CODES[0x7260] = P.GREAT_LORD_8_F
P.HEX_CODES[0x72B4] = P.CAVALIER
P.HEX_CODES[0x7308] = P.CAVALIER
P.HEX_CODES[0x735C] = P.PALADIN_M
P.HEX_CODES[0x73B0] = P.PALADIN_F
P.HEX_CODES[0x7404] = P.ARMOR_KNIGHT
P.HEX_CODES[0x7458] = P.ARMOR_KNIGHT
P.HEX_CODES[0x74AC] = P.GENERAL_M
P.HEX_CODES[0x7500] = P.GENERAL_F
P.HEX_CODES[0x7554] = P.THIEF
P.HEX_CODES[0x75A8] = P.MANAKETE
P.HEX_CODES[0x75FC] = P.MERCENARY
P.HEX_CODES[0x7650] = P.MERCENARY
P.HEX_CODES[0x76A4] = P.HERO_M
P.HEX_CODES[0x76F8] = P.HERO_F
P.HEX_CODES[0x774C] = P.MYRMIDON
P.HEX_CODES[0x77A0] = P.MYRMIDON
P.HEX_CODES[0x77F4] = P.SWORDMASTER_M
P.HEX_CODES[0x7848] = P.SWORDMASTER_F
P.HEX_CODES[0x789C] = P.ASSASSIN_M
P.HEX_CODES[0x78F0] = P.ASSASSIN_F
P.HEX_CODES[0x7944] = P.ARCHER
P.HEX_CODES[0x7998] = P.ARCHER
P.HEX_CODES[0x79EC] = P.SNIPER_M
P.HEX_CODES[0x7A40] = P.SNIPER_F
P.HEX_CODES[0x7A94] = P.TROOPER_M
P.HEX_CODES[0x7AE8] = P.TROOPER_F
P.HEX_CODES[0x7B3C] = P.WYVERN_RIDER
P.HEX_CODES[0x7B90] = P.WYVERN_RIDER
P.HEX_CODES[0x7BE4] = P.WYVERN_LORD_M
P.HEX_CODES[0x7C38] = P.WYVERN_LORD_F
P.HEX_CODES[0x7C8C] = P.WYVERN_KNIGHT_M
P.HEX_CODES[0x7CE0] = P.WYVERN_KNIGHT_F
P.HEX_CODES[0x7D34] = P.MAGE
P.HEX_CODES[0x7D88] = P.MAGE
P.HEX_CODES[0x7DDC] = P.SAGE_M
P.HEX_CODES[0x7E30] = P.SAGE_F
P.HEX_CODES[0x7E84] = P.MAGE_KNIGHT_M
P.HEX_CODES[0x7ED8] = P.MAGE_KNIGHT_F
P.HEX_CODES[0x7F2C] = P.BISHOP_M
P.HEX_CODES[0x7F80] = P.BISHOP_F
P.HEX_CODES[0x7FD4] = P.SHAMAN
P.HEX_CODES[0x8028] = P.SHAMAN
P.HEX_CODES[0x807C] = P.DRUID_M
P.HEX_CODES[0x80D0] = P.DRUID_F
P.HEX_CODES[0x8124] = P.SUMMONER
P.HEX_CODES[0x8178] = P.SUMMONER
P.HEX_CODES[0x81CC] = P.ROGUE
P.HEX_CODES[0x8220] = P.EGG
P.HEX_CODES[0x8274] = P.GREAT_KNIGHT_M
P.HEX_CODES[0x82C8] = P.GREAT_KNIGHT_F
P.HEX_CODES[0x831C] = P.MID_RECRUIT
P.HEX_CODES[0x8370] = P.S_JOURNEYMAN
P.HEX_CODES[0x83C4] = P.S_PUPIL
P.HEX_CODES[0x8418] = P.S_RECRUIT
P.HEX_CODES[0x846C] = P.MANAKETE
P.HEX_CODES[0x84C0] = P.MANAKETE
P.HEX_CODES[0x8514] = P.JOURNEYMAN
P.HEX_CODES[0x8568] = P.PUPIL
P.HEX_CODES[0x85BC] = P.FIGHTER
P.HEX_CODES[0x8610] = P.WARRIOR
P.HEX_CODES[0x8664] = P.Brigand
P.HEX_CODES[0x86B8] = P.PIRATE
P.HEX_CODES[0x870C] = P.BERSERKER
P.HEX_CODES[0x8760] = P.MONK
P.HEX_CODES[0x87B4] = P.PRIEST
P.HEX_CODES[0x8808] = P.BARD
P.HEX_CODES[0x885C] = P.RECRUIT
P.HEX_CODES[0x88B0] = P.PEGASUS_KNIGHT
P.HEX_CODES[0x8904] = P.FALCO_KNIGHT
P.HEX_CODES[0x8958] = P.CLERIC
P.HEX_CODES[0x89AC] = P.TROUBADOUR
P.HEX_CODES[0x8A00] = P.VALKYRIE
P.HEX_CODES[0x8A54] = P.DANCER
P.HEX_CODES[0x8AA8] = P.SOLDIER
P.HEX_CODES[0x8AFC] = P.NECROMANCER
P.HEX_CODES[0x8B50] = P.OTHER -- Fleet
P.HEX_CODES[0x8BA4] = P.OTHER -- Phantom
P.HEX_CODES[0x8BF8] = P.OTHER -- Revenant
P.HEX_CODES[0x8C4C] = P.ENTOMBED
P.HEX_CODES[0x8CA0] = P.OTHER -- Bonewalker
P.HEX_CODES[0x8CF4] = P.OTHER -- Bonewalker
P.HEX_CODES[0x8D48] = P.OTHER_PROMOTED -- Wight
P.HEX_CODES[0x8D9C] = P.OTHER_PROMOTED -- Wight
P.HEX_CODES[0x8DF0] = P.OTHER -- Bael
P.HEX_CODES[0x8E44] = P.OTHER_PROMOTED -- Elder Bael
P.HEX_CODES[0x8E98] = P.OTHER_PROMOTED -- Cyclops
P.HEX_CODES[0x8EEC] = P.OTHER -- Mauthe Doog
P.HEX_CODES[0x8F40] = P.OTHER_PROMOTED -- Gwyllgi
P.HEX_CODES[0x8F94] = P.OTHER -- Tarvos
P.HEX_CODES[0x8FE8] = P.OTHER_PROMOTED -- Maelduin
P.HEX_CODES[0x903C] = P.OTHER -- Mogall
P.HEX_CODES[0x9090] = P.OTHER_PROMOTED -- Arch Mogall
P.HEX_CODES[0x90E4] = P.OTHER_PROMOTED -- Gorgon
P.HEX_CODES[0x9138] = P.EGG -- (Egg)
P.HEX_CODES[0x918C] = P.OTHER -- Gargoyle
P.HEX_CODES[0x91E0] = P.OTHER_PROMOTED -- Deathgoyle
P.HEX_CODES[0x9234] = P.OTHER -- Draco Zombie
P.HEX_CODES[0x9288] = P.OTHER -- Demon King
P.HEX_CODES[0x92DC] = P.ARCHER -- (Archer on Ballista)
P.HEX_CODES[0x9330] = P.ARCHER -- (Archer on Iron Ballista)
P.HEX_CODES[0x9384] = P.ARCHER -- (Archer on Killer Ballista)
P.HEX_CODES[0x93D8] = P.ARCHER -- (Ballista)
P.HEX_CODES[0x942C] = P.ARCHER -- (Iron Ballista)
P.HEX_CODES[0x9480] = P.ARCHER -- (Killer Ballista)
P.HEX_CODES[0x94D4] = P.OTHER -- Civilian
P.HEX_CODES[0x9528] = P.OTHER -- Civilian
P.HEX_CODES[0x957C] = P.OTHER -- Civilian
P.HEX_CODES[0x95D0] = P.OTHER -- Civilian
P.HEX_CODES[0x9624] = P.OTHER -- Civilian
P.HEX_CODES[0x9678] = P.OTHER -- Civilian
P.HEX_CODES[0x96CC] = P.OTHER -- (Peer)
P.HEX_CODES[0x9720] = P.OTHER -- Queen
P.HEX_CODES[0x9774] = P.OTHER -- (Prince)
P.HEX_CODES[0x97C8] = P.OTHER -- Queen
P.HEX_CODES[0x981C] = P.OTHER -- (Empty)
P.HEX_CODES[0x9870] = P.OTHER -- (Dead Prince)
P.HEX_CODES[0x98C4] = P.TRANSPORTER -- (Tent)
P.HEX_CODES[0x9918] = P.OTHER -- Pontifex
P.HEX_CODES[0x996C] = P.OTHER -- (Dead Peer)
P.HEX_CODES[0x99C0] = P.OTHER_PROMOTED -- Cyclops
P.HEX_CODES[0x9A14] = P.OTHER_PROMOTED -- Elder Bael
P.HEX_CODES[0x9A68] = P.MID_JOURNEYMAN
P.HEX_CODES[0x9ABC] = P.MID_PUPIL
end

function P.isNoncombat(class)
	return class == P.DANCER or 
		class == P.BARD or 
		class == P.CLERIC or 
		class == P.PRIEST or 
		class == P.TROUBADOUR or 
		class == P.TRANSPORTER or 
		class == P.TRANSPO_PROMO or 
		class == P.EGG
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
require("feRandomNumbers")

local P = {}
unitData = P




-- luck is in the wrong place relative to what is shown on screen:
-- HP Str Skl Spd Def Res Lck Lvl Exp

local LEVEL_I = 8
local EXP_I = 9

local NAMES = {}
local INDEX_OF_NAME = {} -- useful to set values for a specific unit
local GROWTHS = {}
local GROWTH_WEIGHTS = {}
local BASE_STATS = {}
local BOOSTERS = {}
local BASE_CLASSES = {}
local PROMOTIONS = {}
local PROMOTED_AT = {}
local WILL_PROMOTE_AT = {} -- for dynamic stat weights, some units will not promote at 10
local WILL_END_AT = {} -- for dynamic stat weights, units may not reach lvl 20 by endgame
local HEX_CODES = {}

local DEFAULT_GROWTH_WEIGHTS = {20, 45, 15, 60, 30, 10, 10} 
-- speed>str>def>hp>skl>res=luck
-- these values are not normalized: weights of {2, 4, 2, 5, 3, 1, 1} 
-- make a unit's levels considered 10% as important
-- this set of values are used to scale avgLevelValue for expValueFactor()
local EXP_VALUE_FACTOR_SCALE = 0 -- value of perfect level using default weights
for _, v in ipairs(DEFAULT_GROWTH_WEIGHTS) do
	EXP_VALUE_FACTOR_SCALE = EXP_VALUE_FACTOR_SCALE + 100 * v
end

local function initializeCommonValues()
	for index,name in pairs(NAMES) do INDEX_OF_NAME[name] = index end
	for unit_i = 1, #NAMES do
		GROWTH_WEIGHTS[unit_i] = DEFAULT_GROWTH_WEIGHTS
		BOOSTERS[unit_i] = {0, 0, 0, 0, 0, 0, 0}
		PROMOTED_AT[unit_i] = 0
		WILL_PROMOTE_AT[unit_i] = 10
		WILL_END_AT[unit_i] = 20
	end
end

if GAME_VERSION == 6 then
	-- disambiguate Marcus, Merlinus, Bartre, and Karel from FE7
	NAMES = {
	"Roy", "Marcus6", "Allen", "Lance", "Wolt", 
	"Bors", "Merlinus6", "Ellen", "Dieck", "Wade", 
	"Lott", "Thany", "Chad", "Lugh", "Clarine", 
	"Rutger", "Saul", "Dorothy", "Sue", "Zealot",
	 
	"Treck", "Noah", "Astohl", "Lilina", "Wendy", 
	"Barth", "Ogier", "Fir", "Shin", "Gonzales", 
	"Geese", "Klein", "Tate", "Lalum", "Echidna", 
	"Elphin", "Bartre6", "Ray", "Cath", "Milady", 

	"Percival", "Cecilia", "Sophia", "Igrene", "Garret", 
	"Fa", "Hugh", "Zeis", "Douglas", "Niime", 
	"Dayan", "Juno", "Yodel", "Karel6"}
	GROWTHS = {
	{80, 40, 50, 40, 25, 30, 60}, -- Roy
	{60, 25, 20, 25, 15, 20, 20}, -- Marcus6
	{85, 45, 40, 45, 25, 10, 40}, -- Allen
	{80, 40, 45, 50, 20, 15, 35}, -- Lance
	{80, 40, 50, 40, 20, 10, 40}, -- Wolt
	{90, 30, 30, 40, 35, 10, 50}, -- Bors
	{00, 00, 50, 50, 20, 05, 00}, -- Merlinus6
	{45, 50, 30, 20, 05, 60, 70}, -- Ellen
	{90, 40, 40, 30, 20, 15, 35}, -- Dieck
	{75, 50, 45, 20, 30, 05, 45}, -- Wade 
	{80, 30, 30, 35, 40, 15, 30}, -- Lott
	{45, 30, 55, 60, 10, 25, 60}, -- Thany
	{85, 50, 50, 80, 25, 15, 60}, -- Chad
	{50, 40, 50, 50, 15, 30, 35}, -- Lugh
	{40, 30, 40, 50, 10, 40, 65}, -- Clarine
	{80, 30, 60, 50, 20, 20, 30}, -- Rutger
	{60, 40, 45, 45, 15, 50, 15}, -- Saul
	{85, 50, 45, 45, 15, 15, 35}, -- Dorothy
	{55, 30, 55, 65, 10, 15, 50}, -- Sue
	{75, 25, 20, 20, 30, 15, 15}, -- Zealot
	{85, 40, 30, 35, 30, 05, 50}, -- Treck
	{75, 30, 45, 30, 30, 10, 40}, -- Noah
	{90, 35, 40, 50, 20, 20, 15}, -- Astohl
	{45, 75, 20, 35, 10, 35, 50}, -- Lilina
	{85, 40, 40, 40, 30, 10, 45}, -- Wendy
	{00, 60, 25, 20, 40, 02, 20}, -- Barth
	{85, 40, 30, 45, 20, 15, 55}, -- Oujay
	{75, 25, 50, 55, 15, 20, 50}, -- Fir
	{75, 45, 50, 50, 10, 15, 25}, -- Shin
	{90, 60, 15, 50, 25, 05, 35}, -- Gonzales
	{85, 50, 30, 40, 20, 10, 40}, -- Geese
	{60, 35, 40, 45, 15, 25, 50}, -- Klein
	{60, 40, 45, 55, 15, 20, 40}, -- Tate
	{70, 10, 05, 70, 20, 30, 80}, -- Lalum
	{75, 30, 25, 30, 15, 15, 20}, -- Echidna
	{80, 05, 05, 65, 25, 55, 65}, -- Elphin
	{70, 40, 20, 30, 20, 05, 20}, -- Bartre6
	{55, 45, 55, 40, 15, 35, 15}, -- Ray
	{80, 40, 45, 85, 15, 20, 50}, -- Cath
	{75, 50, 50, 45, 20, 05, 25}, -- Miredy
	{75, 30, 25, 35, 20, 10, 20}, -- Percival
	{60, 35, 45, 25, 20, 25, 25}, -- Cecilia
	{60, 55, 40, 30, 20, 55, 20}, -- Sofiya
	{70, 35, 25, 35, 10, 05, 20}, -- Igrene
	{70, 45, 25, 25, 15, 05, 15}, -- Garret
	{30, 90, 85, 65, 30, 50, 50}, -- Fa
	{75, 30, 30, 45, 20, 15, 25}, -- Hugh
	{80, 60, 50, 35, 25, 05, 20}, -- Zeis
	{60, 30, 30, 30, 30, 05, 20}, -- Douglas
	{25, 15, 15, 15, 15, 20, 05}, -- Niime
	{55, 20, 20, 15, 10, 10, 20}, -- Dayan
	{50, 20, 35, 30, 10, 10, 45}, -- Juno
	{20, 30, 15, 10, 10, 20, 20}, -- Yodel
	{10, 30, 40, 40, 10, 00, 20}  -- Karel6
	}
	BASE_STATS = {
	{18, 05, 05, 07, 05, 00, 07, 01}, -- Roy
	{32, 09, 14, 11, 09, 08, 10, 01}, -- Marcus6
	{21, 07, 04, 06, 06, 00, 03, 01}, -- Allen
	{20, 05, 06, 08, 06, 00, 02, 01}, -- Lance
	{18, 04, 04, 05, 04, 00, 02, 01}, -- Wolt
	{20, 07, 04, 03, 11, 00, 04, 01}, -- Bors
	{15, 00, 03, 03, 03, 00, 10, 01}, -- Merlinus6
	{16, 01, 06, 08, 00, 06, 08, 02}, -- Ellen
	{26, 09, 12, 10, 06, 01, 05, 05}, -- Dieck
	{28, 08, 03, 05, 03, 00, 04, 02}, -- Wade
	{29, 07, 06, 07, 04, 01, 02, 03}, -- Lott
	{17, 04, 06, 12, 06, 05, 05, 01}, -- Thany
	{16, 03, 03, 10, 02, 00, 04, 01}, -- Chad
	{16, 04, 05, 06, 03, 05, 05, 01}, -- Lugh
	{15, 02, 05, 09, 02, 05, 08, 01}, -- Clarine
	{22, 07, 12, 13, 05, 00, 02, 04}, -- Rutger
	{20, 04, 06, 10, 02, 05, 02, 05}, -- Saul
	{19, 05, 06, 06, 04, 02, 03, 03}, -- Dorothy
	{18, 05, 07, 08, 05, 00, 04, 01}, -- Sue
	{35, 10, 12, 13, 11, 07, 05, 01}, -- Zealot
	{25, 08, 06, 07, 08, 00, 05, 04}, -- Treck
	{27, 08, 07, 09, 07, 01, 06, 07}, -- Noah
	{25, 07, 08, 15, 07, 03, 11, 10}, -- Astohl
	{16, 05, 05, 04, 02, 07, 04, 01}, -- Lilina
	{19, 04, 03, 03, 08, 01, 06, 01}, -- Wendy
	{25, 10, 06, 05, 14, 01, 02, 09}, -- Barth
	{24, 07, 10, 09, 04, 00, 06, 03}, -- Oujay
	{19, 06, 09, 10, 03, 01, 03, 01}, -- Fir
	{24, 07, 08, 10, 07, 00, 06, 05}, -- Shin
	{36, 12, 05, 09, 06, 00, 05, 05}, -- Gonzales, level depends on route
	{33, 10, 09, 09, 08, 00, 09, 10}, -- Geese
	{27, 13, 13, 11, 08, 06, 10, 01}, -- Klein
	{22, 06, 08, 11, 07, 06, 03, 08}, -- Tate
	{14, 01, 02, 11, 02, 04, 09, 01}, -- Lalum
	{35, 13, 19, 18, 08, 07, 06, 01}, -- Echidna
	{15, 01, 03, 10, 04, 01, 11, 01}, -- Elphin
	{48, 22, 11, 10, 10, 03, 14, 02}, -- Bartre6, note serenes is incorrect, level 2, not 1
	{23, 12, 09, 09, 05, 10, 06, 12}, -- Ray
	{16, 03, 07, 11, 02, 01, 08, 05}, -- Cath, more stats if recruited later
	{30, 12, 11, 10, 13, 03, 05, 10}, -- Miredy
	{43, 17, 13, 18, 14, 11, 12, 05}, -- Percival
	{30, 11, 07, 10, 07, 13, 10, 01}, -- Cecilia
	{15, 06, 02, 04, 01, 08, 03, 01}, -- Sofiya
	{32, 16, 18, 15, 11, 10, 09, 01}, -- Igrene
	{49, 17, 13, 10, 09, 04, 12, 01}, -- Garret
	{16, 02, 02, 03, 02, 06, 07, 01}, -- Fa
	{26, 13, 11, 12, 09, 09, 10, 15}, -- Hugh
	{28, 14, 09, 08, 12, 02, 06, 07}, -- Zeis
	{46, 19, 13, 08, 20, 05, 11, 08}, -- Douglas
	{25, 21, 20, 16, 05, 18, 15, 18}, -- Niime
	{43, 14, 16, 20, 10, 12, 12, 12}, -- Dayan
	{33, 11, 14, 16, 08, 12, 14, 09}, -- Juno
	{35, 19, 18, 14, 05, 30, 11, 20}, -- Yodel
	{44, 20, 28, 23, 15, 13, 18, 19}  -- Karel6
	}
	BASE_CLASSES = {
	classes.LORD, 			-- Roy
	classes.PALADIN_M, 		-- Marcus
	classes.CAVALIER, 		-- Allen
	classes.CAVALIER, 		-- Lance
	classes.ARCHER, 		-- Wolt 
	classes.ARMOR_KNIGHT, 	-- Bors 
	classes.TRANSPORTER, 	-- Merlinus
	classes.CLERIC, 		-- Ellen
	classes.MERCENARY, 		-- Dieck
	classes.FIGHTER, 		-- Wade
	classes.FIGHTER, 		-- Lott
	classes.PEGASUS_KNIGHT, -- Thany
	classes.THIEF, 			-- Chad
	classes.MAGE, 			-- Lugh
	classes.TROUBADOUR, 	-- Clarine 
	classes.MYRMIDON, 		-- Rutger 
	classes.PRIEST, 		-- Saul
	classes.ARCHER, 		-- Dorothy 
	classes.NOMAD, 			-- Sue 
	classes.PALADIN_M, 		-- Zealot
	classes.CAVALIER, 		-- Treck
	classes.CAVALIER, 		-- Noah
	classes.THIEF, 			-- Astohl
	classes.MAGE, 			-- Lilina
	classes.ARMOR_KNIGHT, 	-- Wendy
	classes.ARMOR_KNIGHT, 	-- Barth
	classes.MERCENARY, 		-- Oujay
	classes.MYRMIDON, 		-- Fir
	classes.NOMAD, 			-- Shin
	classes.BRIGAND, 		-- Gonzales
	classes.PIRATE, 		-- Geese
	classes.SNIPER_M, 		-- Klein
	classes.PEGASUS_KNIGHT, -- Tate
	classes.DANCER, 		-- Lalum
	classes.HERO_F, 		-- Echidna
	classes.BARD, 			-- Elphin
	classes.WARRIOR, 		-- Bartre
	classes.SHAMAN, 		-- Ray
	classes.THIEF, 			-- Cath
	classes.WYVERN_RIDER, 	-- Miredy 
	classes.PALADIN_M, 		-- Percival
	classes.VALKYRIE, 		-- Cecilia
	classes.SHAMAN, 		-- Sofiya
	classes.SNIPER_F, 		-- Igrene
	classes.BERSERKER, 		-- Garret
	classes.MANAKETE, 		-- Fa
	classes.MAGE, 			-- Hugh
	classes.WYVERN_RIDER, 	-- Zeis
	classes.GENERAL_M, 		-- Douglas
	classes.DRUID_F, 		-- Niime
	classes.TROOPER_M, 		-- Dayan
	classes.FALCO_KNIGHT, 	-- Juno
	classes.BISHOP_M, 		-- Yodel
	classes.SWORDMASTER_M 	-- Karel
	}
	PROMOTIONS = {
	classes.MASTER_LORD, 	-- Roy
	classes.PALADIN_M, 		-- Marcus
	classes.PALADIN_M, 		-- Allen
	classes.PALADIN_M, 		-- Lance
	classes.SNIPER_M, 		-- Wolt
	classes.GENERAL_M, 		-- Bors
	classes.TRANSPORTER, 	-- Merlinus
	classes.BISHOP_F, 		-- Ellen
	classes.HERO_M, 		-- Dieck
	classes.WARRIOR, 		-- Wade
	classes.WARRIOR, 		-- Lott
	classes.FALCO_KNIGHT, 	-- Thany
	classes.THIEF, 			-- Chad
	classes.SAGE_M, 		-- Lugh
	classes.VALKYRIE, 		-- Clarine
	classes.SWORDMASTER_M, 	-- Rutger
	classes.BISHOP_M, 		-- Saul
	classes.SNIPER_F, 		-- Dorothy
	classes.TROOPER_F, 		-- Sue
	classes.PALADIN_M, 		-- Zealot
	classes.PALADIN_M, 		-- Treck
	classes.PALADIN_M, 		-- Noah
	classes.THIEF, 			-- Astohl
	classes.SAGE_F, 		-- Lilina
	classes.GENERAL_F, 		-- Wendy
	classes.GENERAL_M, 		-- Barth
	classes.HERO_M, 		-- Oujay
	classes.SWORDMASTER_F, 	-- Fir
	classes.TROOPER_M, 		-- Shin 
	classes.BERSERKER, 		-- Gonzales
	classes.BERSERKER, 		-- Geese
	classes.SNIPER_M, 		-- Klein
	classes.FALCO_KNIGHT, 	-- Tate
	classes.DANCER, 		-- Lalum
	classes.HERO_F, 		-- Echidna
	classes.BARD, 			-- Elphin
	classes.WARRIOR, 		-- Bartre
	classes.DRUID_M, 		-- Ray
	classes.THIEF, 			-- Cath
	classes.WYVERN_LORD_F, 	-- Miredy
	classes.PALADIN_M, 		-- Percival
	classes.VALKYRIE, 		-- Cecilia
	classes.DRUID_F, 		-- Sofiya
	classes.SNIPER_F, 		-- Igrene
	classes.BERSERKER, 		-- Garret
	classes.MANAKETE, 		-- Fa
	classes.SAGE_M, 		-- Hugh
	classes.WYVERN_LORD_M, 	-- Zeis
	classes.GENERAL_M, 		-- Douglas
	classes.DRUID_F, 		-- Niime
	classes.TROOPER_M, 		-- Dayan
	classes.FALCO_KNIGHT, 	-- Juno
	classes.BISHOP_M, 		-- Yodel
	classes.SWORDMASTER_M 	-- Karel
	}

	initializeCommonValues()
	
	do -- HEX_CODES
HEX_CODES[0x76D0] = "Roy"
HEX_CODES[0x7700] = "Clarine"
HEX_CODES[0x7730] = "Fa"
HEX_CODES[0x7760] = "Shin"
HEX_CODES[0x7790] = "Sue"
HEX_CODES[0x77C0] = "Dayan"
HEX_CODES[0x70F0] = "Dayan"
HEX_CODES[0x7820] = "Barth"
HEX_CODES[0x7850] = "Bors"
HEX_CODES[0x7880] = "Wendy"
HEX_CODES[0x78B0] = "Douglas"
HEX_CODES[0x7910] = "Wolt"
HEX_CODES[0x7940] = "Dorothy"
HEX_CODES[0x7970] = "Klein"
HEX_CODES[0x79A0] = "Saul"
HEX_CODES[0x79D0] = "Ellen"
HEX_CODES[0x7A00] = "Yodel"
HEX_CODES[0x7A30] = "Yodel"
HEX_CODES[0x7A60] = "Chad"
HEX_CODES[0x7A90] = "Karel6"
HEX_CODES[0x7AC0] = "Fir"
HEX_CODES[0x7AF0] = "Rutger"
HEX_CODES[0x7B20] = "Dieck"
HEX_CODES[0x7B50] = "Oujay"
HEX_CODES[0x7B80] = "Garret"
HEX_CODES[0x7BB0] = "Allen"
HEX_CODES[0x7BE0] = "Lance"
HEX_CODES[0x7C10] = "Percival"
HEX_CODES[0x7C40] = "Igrene"
HEX_CODES[0x7C70] = "Marcus6"
HEX_CODES[0x7CA0] = "Astohl"
HEX_CODES[0x7CD0] = "Wade"
HEX_CODES[0x7D00] = "Lott"
HEX_CODES[0x7D30] = "Bartre6"
HEX_CODES[0x7D60] = "Bartre6"
HEX_CODES[0x7D90] = "Lugh"
HEX_CODES[0x7DC0] = "Lilina"
HEX_CODES[0x7DF0] = "Hugh"
HEX_CODES[0x7E20] = "Niime"
HEX_CODES[0x7E50] = "Niime"
HEX_CODES[0x7E80] = "Ray"
HEX_CODES[0x7EB0] = "Lalam"
HEX_CODES[0x7EE0] = "Juno"
HEX_CODES[0x7F10] = "Juno"
HEX_CODES[0x7F40] = "Tate"
HEX_CODES[0x7F70] = "Tate"
HEX_CODES[0x7FA0] = "Tate"
HEX_CODES[0x7FD0] = "Thany"
HEX_CODES[0x8000] = "Zeis"
HEX_CODES[0x8030] = "Gale"
HEX_CODES[0x8060] = "Elphin"
HEX_CODES[0x8090] = "Cath"
HEX_CODES[0x80C0] = "Sophia"
HEX_CODES[0x80F0] = "Milady"
HEX_CODES[0x8120] = "Gonzales"
HEX_CODES[0x8150] = "Gonzales"
HEX_CODES[0x8180] = "Noah"
HEX_CODES[0x81B0] = "Treck"
HEX_CODES[0x81E0] = "Zealot"
HEX_CODES[0x8210] = "Echidna"
HEX_CODES[0x8240] = "Echidna"
HEX_CODES[0x8270] = "Cecilia"
HEX_CODES[0x82A0] = "Geese"
HEX_CODES[0x82D0] = "Geese"
HEX_CODES[0x8300] = "Merlinus6"
HEX_CODES[0x8330] = "Eliwood"
HEX_CODES[0x8360] = "Guinevere"
	end
	
	-- expected hard mode stats, actual stats are rng dependent
	if HARD_MODE then
		BASE_STATS[INDEX_OF_NAME["Rutger"]]   = {26, 09, 14, 15, 06, 01, 04, 04}
		BASE_STATS[INDEX_OF_NAME["Fir"]]      = {25, 09, 12, 13, 04, 02, 05, 01}
		BASE_STATS[INDEX_OF_NAME["Shin"]]     = {29, 09, 11, 14, 08, 01, 08, 05}
		BASE_STATS[INDEX_OF_NAME["Gonzales"]] = {43, 16, 07, 11, 06, 07, 01, 05} -- level depends on route
		BASE_STATS[INDEX_OF_NAME["Klein"]]    = {33, 16, 16, 13, 09, 07, 13, 01} -- depends on route
		BASE_STATS[INDEX_OF_NAME["Tate"]]     = {28, 09, 12, 15, 08, 08, 06, 08} -- depends on route
		BASE_STATS[INDEX_OF_NAME["Cath"]]     = {20, 03, 11, 15, 02, 03, 12, 05} -- more stats if recruited later
		BASE_STATS[INDEX_OF_NAME["Milady"]]   = {38, 17, 15, 13, 16, 04, 08, 10}
		BASE_STATS[INDEX_OF_NAME["Percival"]] = {51, 20, 16, 20, 15, 13, 15, 05}
		BASE_STATS[INDEX_OF_NAME["Garret"]]   = {55, 21, 16, 11, 10, 05, 14, 05}
		BASE_STATS[INDEX_OF_NAME["Zeis"]]     = {37, 19, 13, 11, 15, 03, 09, 07}
	end

	-- ideally won't take more than 1 hit anyway, so hp is closer to def+res
	-- speed gives twice the avoid of luck, but luck also gives crit evade so 2 points luck slightly better
	GROWTH_WEIGHTS[INDEX_OF_NAME["Lalum"]] = {30, 00, 00, 19, 30, 10, 10} 
	GROWTH_WEIGHTS[INDEX_OF_NAME["Elphin"]] = {30, 00, 00, 19, 30, 10, 10}
end

if GAME_VERSION == 7 then
	NAMES = {
	"Eliwood", "Lowen", "Marcus", "Rebecca", "Dorcas",
	"Bartre", "Hector", "Oswin", "Serra", "Matthew",
	"Guy", "Merlinus", "Erk", "Priscilla", "Lyn",
	"Wil", "Kent", "Sain", "Florina", "Raven",

	"Lucius", "Canas", "Dart", "Fiora", "Legault",
	"Ninian/Nils", "Isadora", "Heath", "Rath", "Hawkeye",
	"Geitz", "Wallace", "Farina", "Pent", "Louise",
	"Karel", "Harken", "Nino", "Jaffar", "Vaida",

	"Karla", "Renault", "Athos"
	}
	GROWTHS = {
	{80, 45, 50, 40, 30, 35, 45}, -- Eliwood
	{90, 30, 30, 30, 40, 30, 50}, -- Lowen
	{65, 30, 50, 25, 15, 35, 30}, -- Marcus
	{60, 40, 50, 60, 15, 30, 50}, -- Rebecca
	{80, 60, 40, 20, 25, 15, 45}, -- Dorcas
	{85, 50, 35, 40, 30, 25, 30}, -- Bartre
	{90, 60, 45, 35, 50, 25, 30}, -- Hector
	{90, 40, 30, 30, 55, 30, 35}, -- Oswin
	{50, 50, 30, 40, 15, 55, 60}, -- Serra
	{75, 30, 40, 70, 25, 20, 50}, -- Matthew
	{75, 30, 50, 70, 15, 25, 45}, -- Guy
	{20, 00, 90, 90, 30, 15, 00}, -- Merlinus +hp, lck
	{65, 40, 40, 50, 20, 40, 30}, -- Erk
	{45, 40, 50, 40, 15, 50, 65}, -- Priscilla
	{70, 40, 60, 60, 20, 30, 55}, -- Lyn
	{75, 50, 50, 40, 20, 25, 40}, -- Wil
	{85, 40, 50, 45, 25, 25, 20}, -- Kent
	{80, 60, 35, 40, 20, 20, 35}, -- Sain
	{60, 40, 50, 55, 15, 35, 50}, -- Florina
	{85, 55, 40, 45, 25, 15, 35}, -- Raven
	{55, 60, 50, 40, 10, 60, 20}, -- Lucius
	{70, 45, 40, 35, 25, 45, 25}, -- Canas
	{70, 65, 20, 60, 20, 15, 35}, -- Dart
	{70, 35, 60, 50, 20, 50, 30}, -- Fiora
	{60, 25, 45, 60, 25, 25, 60}, -- Legault
	{85, 05, 05, 70, 30, 70, 80}, -- Nils/Ninian
	{75, 30, 35, 50, 20, 25, 45}, -- Isadora
	{80, 50, 50, 45, 30, 20, 20}, -- Heath
	{80, 50, 40, 50, 10, 25, 30}, -- Rath
	{50, 40, 30, 25, 20, 35, 40}, -- Hawkeye
	{85, 50, 30, 40, 20, 20, 40}, -- Geitz
	{70, 45, 40, 20, 35, 35, 30}, -- Wallace
	{75, 50, 40, 45, 25, 30, 45}, -- Farina
	{50, 30, 20, 40, 30, 35, 40}, -- Pent
	{60, 40, 40, 40, 20, 30, 30}, -- Louise
	{70, 30, 50, 50, 10, 15, 30}, -- Karel
	{80, 35, 30, 40, 30, 25, 20}, -- Harken
	{55, 50, 55, 60, 15, 50, 45}, -- Nino
	{65, 15, 40, 35, 30, 30, 20}, -- Jaffar
	{60, 45, 25, 40, 25, 15, 30}, -- Vaida
	{60, 25, 45, 55, 10, 20, 40}, -- Karla
	{60, 40, 30, 35, 20, 40, 15}, -- Renault
	{00, 00, 00, 00, 00, 00, 00}  -- Athos
	}
	BASE_STATS = {
	{18, 05, 05, 07, 05, 00, 07, 01}, -- Eliwood
	{23, 07, 05, 07, 07, 00, 03, 02}, -- Lowen
	{31, 15, 15, 11, 10, 08, 08, 01}, -- Marcus
	{17, 04, 05, 06, 03, 01, 04, 01}, -- Rebecca
	{30, 07, 07, 06, 03, 00, 03, 03}, -- Dorcas
	{29, 09, 05, 03, 04, 00, 04, 02}, -- Bartre
	{19, 07, 04, 05, 08, 00, 03, 01}, -- Hector
	{28, 13, 09, 05, 13, 03, 03, 09}, -- Oswin
	{17, 02, 05, 08, 02, 05, 06, 01}, -- Serra
	{18, 04, 04, 11, 03, 00, 02, 02}, -- Matthew
	{21, 06, 11, 11, 05, 00, 05, 03}, -- Guy
	{18, 00, 04, 05, 05, 02, 12, 05}, -- Merlinus
	{17, 05, 06, 07, 02, 04, 03, 01}, -- Erk
	{16, 06, 06, 08, 03, 06, 07, 03}, -- Priscilla
	{18, 05, 10, 11, 02, 00, 05, 04}, -- Lyn
	{21, 06, 05, 06, 05, 01, 07, 04}, -- Wil
	{23, 08, 07, 08, 06, 01, 04, 05}, -- Kent
	{22, 09, 05, 07, 07, 00, 05, 04}, -- Sain
	{18, 06, 08, 09, 04, 05, 08, 03}, -- Florina
	{25, 08, 11, 13, 05, 01, 02, 05}, -- Raven
	{18, 07, 06, 10, 01, 06, 02, 04}, -- Lucius
	{21, 10, 09, 08, 05, 08, 07, 08}, -- Canas
	{34, 12, 08, 08, 06, 01, 03, 08}, -- Dart
	{21, 08, 11, 13, 06, 07, 06, 07}, -- Fiora
	{26, 08, 11, 15, 08, 03, 10, 12}, -- Legault
	{14, 00, 00, 12, 05, 04, 10, 01}, -- Ninian/Nils
	{28, 13, 12, 16, 08, 06, 10, 01}, -- Isadora
	{28, 11, 08, 07, 10, 01, 07, 07}, -- Heath
	{27, 09, 10, 11, 08, 02, 05, 09}, -- Rath
	{50, 18, 14, 11, 14, 10, 13, 04}, -- Hawkeye
	{40, 17, 12, 13, 11, 03, 10, 03}, -- Geitz
	{34, 16, 09, 08, 19, 05, 10, 01}, -- Wallace
	{24, 10, 13, 14, 10, 12, 10, 12}, -- Farina
	{33, 18, 21, 17, 11, 16, 14, 06}, -- Pent
	{28, 12, 14, 17, 09, 12, 16, 04}, -- Louise
	{31, 16, 23, 20, 13, 12, 15, 08}, -- Karel
	{38, 21, 20, 17, 15, 10, 12, 08}, -- Harken
	{19, 07, 08, 11, 04, 07, 10, 05}, -- Nino
	{34, 19, 25, 24, 15, 11, 10, 13}, -- Jaffar
	{43, 20, 19, 13, 21, 06, 11, 09}, -- Vaida
	{29, 14, 21, 18, 11, 12, 16, 05}, -- Karla
	{43, 12, 22, 20, 15, 18, 10, 16}, -- Renault
	{40, 30, 24, 20, 20, 28, 25, 20}, -- Athos
	}
	BASE_CLASSES = {
	classes.LORD,			-- Eliwood
	classes.CAVALIER,		-- Lowen
	classes.PALADIN_M,		-- Marcus
	classes.ARCHER,			-- Rebecca
	classes.FIGHTER,		-- Dorcas
	classes.FIGHTER,		-- Bartre
	classes.LORD,			-- Hector
	classes.ARMOR_KNIGHT,	-- Oswin
	classes.CLERIC,			-- Serra
	classes.THIEF,			-- Matthew
	classes.MYRMIDON,		-- Guy
	classes.TRANSPORTER,	-- Merlinus
	classes.MAGE,			-- Erk
	classes.TROUBADOUR,		-- Priscilla
	classes.LORD,			-- Lyn
	classes.ARCHER,			-- Wil
	classes.CAVALIER,		-- Kent
	classes.CAVALIER,		-- Sain
	classes.PEGASUS_KNIGHT, -- Florina
	classes.MERCENARY,		-- Raven
	classes.MONK,			-- Lucius
	classes.SHAMAN,			-- Canas
	classes.PIRATE,			-- Dart
	classes.PEGASUS_KNIGHT, -- Fiora
	classes.THIEF,			-- Legault
	classes.DANCER,			-- Ninian/Nils
	classes.PALADIN_F,		-- Isadora
	classes.WYVERN_RIDER,	-- Heath
	classes.NOMAD,			-- Rath
	classes.BERSERKER,		-- Hawkeye
	classes.WARRIOR,		-- Geitz
	classes.GENERAL_M,		-- Wallace
	classes.PEGASUS_KNIGHT, -- Farina
	classes.SAGE_M,			-- Pent
	classes.SNIPER_F,		-- Louise
	classes.SWORDMASTER_M,	-- Karel
	classes.HERO_M,			-- Harken
	classes.MAGE,			-- Nino
	classes.ASSASSIN_M,		-- Jaffar
	classes.WYVERN_LORD_F,	-- Vaida
	classes.SWORDMASTER_F,	-- Karla
	classes.BISHOP_M,		-- Renault
	classes.ARCHSAGE		-- Athos
	}
	PROMOTIONS = {
	classes.KNIGHT_LORD,	-- Eliwood
	classes.PALADIN_M,		-- Lowen
	classes.PALADIN_M,		-- Marcus
	classes.SNIPER_F,		-- Rebecca
	classes.WARRIOR,		-- Dorcas
	classes.WARRIOR,		-- Bartre
	classes.GREAT_LORD_7,	-- Hector
	classes.GENERAL_M,		-- Oswin
	classes.BISHOP_F,		-- Serra
	classes.ASSASSIN_M,		-- Matthew
	classes.SWORDMASTER_M,	-- Guy
	classes.TRANSPORTER,	-- Merlinus
	classes.SAGE_M,			-- Erk
	classes.VALKYRIE,		-- Priscilla
	classes.BLADE_LORD,		-- Lyn
	classes.SNIPER_M,		-- Wil
	classes.PALADIN_M,		-- Kent
	classes.PALADIN_M,		-- Sain
	classes.FALCO_KNIGHT, 	-- Florina
	classes.HERO_M,			-- Raven
	classes.BISHOP_M,		-- Lucius
	classes.DRUID_M,		-- Canas
	classes.BERSERKER,		-- Dart
	classes.FALCO_KNIGHT, 	-- Fiora
	classes.ASSASSIN_M,		-- Legault
	classes.DANCER,			-- Ninian/Nils
	classes.PALADIN_F,		-- Isadora
	classes.WYVERN_LORD_M,	-- Heath
	classes.TROOPER_M,		-- Rath
	classes.BERSERKER,		-- Hawkeye
	classes.WARRIOR,		-- Geitz
	classes.GENERAL_M,		-- Wallace
	classes.FALCO_KNIGHT, 	-- Farina
	classes.SAGE_M,			-- Pent
	classes.SNIPER_F,		-- Louise
	classes.SWORDMASTER_M,	-- Karel
	classes.HERO_M,			-- Harken
	classes.SAGE_F,			-- Nino
	classes.ASSASSIN_M,		-- Jaffar
	classes.WYVERN_LORD_F,	-- Vaida
	classes.SWORDMASTER_F,	-- Karla
	classes.BISHOP_M,		-- Renault
	classes.ARCHSAGE		-- Athos
	}

	initializeCommonValues()
	
	do -- HEX_CODES
HEX_CODES[0xCE4C] = "Eliwood"
HEX_CODES[0xCE80] = "Hector"
HEX_CODES[0xCEB4] = "Lyn"
HEX_CODES[0xCEE8] = "Raven"
HEX_CODES[0xCF1C] = "Geitz"
HEX_CODES[0xCF50] = "Guy"
HEX_CODES[0xCF84] = "Karel"
HEX_CODES[0xCFB8] = "Dorcas"
HEX_CODES[0xCFEC] = "Bartre"
HEX_CODES[0xD020] = "Citizen"
HEX_CODES[0xD054] = "Oswin"
HEX_CODES[0xD088] = "Fargus"
HEX_CODES[0xD0BC] = "Wil"
HEX_CODES[0xD0F0] = "Rebecca"
HEX_CODES[0xD124] = "Louise"
HEX_CODES[0xD158] = "Lucius"
HEX_CODES[0xD18C] = "Serra"
HEX_CODES[0xD1C0] = "Renault"
HEX_CODES[0xD1F4] = "Erk"
HEX_CODES[0xD228] = "Nino"
HEX_CODES[0xD25C] = "Pent"
HEX_CODES[0xD290] = "Canas"
HEX_CODES[0xD2C4] = "Kent"
HEX_CODES[0xD2F8] = "Sain"
HEX_CODES[0xD32C] = "Lowen"
HEX_CODES[0xD360] = "Marcus"
HEX_CODES[0xD394] = "Priscilla"
HEX_CODES[0xD3C8] = "Rath"
HEX_CODES[0xD3FC] = "Florina"
HEX_CODES[0xD430] = "Fiora"
HEX_CODES[0xD464] = "Farina"
HEX_CODES[0xD498] = "Heath"
HEX_CODES[0xD4CC] = "Vaida"
HEX_CODES[0xD500] = "Hawkeye"
HEX_CODES[0xD534] = "Matthew"
HEX_CODES[0xD568] = "Jaffar"
HEX_CODES[0xD59C] = "Ninian"
HEX_CODES[0xD5D0] = "Nils"
HEX_CODES[0xD604] = "Athos"
HEX_CODES[0xD638] = "Merlinus"
HEX_CODES[0xD66C] = "Nils"
HEX_CODES[0xD6A0] = "Uther" -- (no thumbnail)
HEX_CODES[0xD6D4] = "Vaida"
HEX_CODES[0xD708] = "Wallace"
HEX_CODES[0xD73C] = "Lyn"
HEX_CODES[0xD770] = "Wil"
HEX_CODES[0xD7A4] = "Kent"
HEX_CODES[0xD7D8] = "Sain"
HEX_CODES[0xD80C] = "Florina"
HEX_CODES[0xD840] = "Rath"
HEX_CODES[0xD874] = "Dart"
HEX_CODES[0xD8A8] = "Isadora"
HEX_CODES[0xD8DC] = "Eleanora" -- (no thumbnail)
HEX_CODES[0xD910] = "Legault"
HEX_CODES[0xD944] = "Karla"
HEX_CODES[0xD978] = "Harken"
HEX_CODES[0xD9AC] = "Leila" -- (no thumbnail)
HEX_CODES[0xD9E0] = "Bramimond" -- (no thumbnail)
HEX_CODES[0xDA14] = "Kishuna"
HEX_CODES[0xDA48] = "Groznyi"
HEX_CODES[0xDA7C] = "Wire"
HEX_CODES[0xDAB0] = "Bandit"
HEX_CODES[0xDAE4] = "Zagan"
HEX_CODES[0xDB18] = "Boies"
HEX_CODES[0xDB4C] = "Puzon"
HEX_CODES[0xDB80] = "Bandit"
HEX_CODES[0xDBB4] = "Santals" -- (no thumbnail)
HEX_CODES[0xDBE8] = "Nergal"
HEX_CODES[0xDC1C] = "Erik"
HEX_CODES[0xDC50] = "Sealen"
HEX_CODES[0xDC84] = "Bauker"
HEX_CODES[0xDCB8] = "Bernard"
HEX_CODES[0xDCEC] = "Damian"
HEX_CODES[0xDD20] = "Zoldam"
HEX_CODES[0xDD54] = "Uhai"
HEX_CODES[0xDD88] = "Aion"
HEX_CODES[0xDDBC] = "Darin"
HEX_CODES[0xDDF0] = "Cameron"
HEX_CODES[0xDE24] = "Oleg"
HEX_CODES[0xDE58] = "Eubans"
HEX_CODES[0xDE8C] = "Ursula"
HEX_CODES[0xDEC0] = "Black Fang"
HEX_CODES[0xDEF4] = "Paul"
HEX_CODES[0xDF28] = "Jasmine"
HEX_CODES[0xDF5C] = "Black Fang"
HEX_CODES[0xDF90] = "Jerme" --  (morph)
HEX_CODES[0xDFC4] = "Pascal"
HEX_CODES[0xDFF8] = "Kenneth"
HEX_CODES[0xE02C] = "Jerme"
HEX_CODES[0xE060] = "Maxime"
HEX_CODES[0xE094] = "Sonia"
HEX_CODES[0xE0C8] = "Teodor"
HEX_CODES[0xE0FC] = "Georg"
HEX_CODES[0xE130] = "Kaim"
HEX_CODES[0xE164] = "Merc"
HEX_CODES[0xE198] = "Denning"
HEX_CODES[0xE1CC] = "Bern"
HEX_CODES[0xE200] = "Morph"
HEX_CODES[0xE234] = "Lloyd"
HEX_CODES[0xE268] = "Linus"
HEX_CODES[0xE29C] = "Lloyd"
HEX_CODES[0xE2D0] = "Linus"
HEX_CODES[0xE304] = "Bandit"
HEX_CODES[0xE338] = "Bandit"
HEX_CODES[0xE36C] = "Bandit"
HEX_CODES[0xE3A0] = "Laus"
HEX_CODES[0xE3D4] = "Laus"
HEX_CODES[0xE408] = "Pirate"
HEX_CODES[0xE43C] = "Black Fang"
HEX_CODES[0xE470] = "Black Fang"
HEX_CODES[0xE4A4] = "Ostia"
HEX_CODES[0xE4D8] = "Black Fang"
HEX_CODES[0xE50C] = "Guardian"
HEX_CODES[0xE540] = "Morph"
HEX_CODES[0xE574] = "Morph"
HEX_CODES[0xE5A8] = "Morph"
HEX_CODES[0xE5DC] = "Caelin"
HEX_CODES[0xE610] = "Caelin"
HEX_CODES[0xE644] = "Caelin"
HEX_CODES[0xE678] = "Laus"
HEX_CODES[0xE6AC] = "Laus"
HEX_CODES[0xE6E0] = "Zephiel"
HEX_CODES[0xE714] = "Elbert" -- (no thumbnail)
HEX_CODES[0xE748] = "Black Fang"
HEX_CODES[0xE77C] = "Black Fang"
HEX_CODES[0xE7B0] = "Black Fang"
HEX_CODES[0xE7E4] = "Morph"
HEX_CODES[0xE818] = "Morph"
HEX_CODES[0xE84C] = "Morph"
HEX_CODES[0xE880] = "Morph"
HEX_CODES[0xE8B4] = "Black Fang"
HEX_CODES[0xE8E8] = "Brendan"
HEX_CODES[0xE91C] = "Limstella"
HEX_CODES[0xE950] = "Dragon"
HEX_CODES[0xE984] = "Batta"
HEX_CODES[0xE9B8] = "Bandit"
HEX_CODES[0xE9EC] = "Zugu"
HEX_CODES[0xEA20] = "Bandit"
HEX_CODES[0xEA54] = "Bandit"
HEX_CODES[0xEA88] = "Bandit"
HEX_CODES[0xEABC] = "Glass"
HEX_CODES[0xEAF0] = "Migal"
HEX_CODES[0xEB24] = "Bandit"
HEX_CODES[0xEB58] = "Bandit"
HEX_CODES[0xEB8C] = "Bandit"
HEX_CODES[0xEBC0] = "Bandit"
HEX_CODES[0xEBF4] = "Bandit"
HEX_CODES[0xEC28] = "Carjiga"
HEX_CODES[0xEC5C] = "Bandit"
HEX_CODES[0xEC90] = "Bandit"
HEX_CODES[0xECC4] = "Bandit"
HEX_CODES[0xECF8] = "Bandit"
HEX_CODES[0xED2C] = "Bug"
HEX_CODES[0xED60] = "Bandit"
HEX_CODES[0xED94] = "Bandit"
HEX_CODES[0xEDC8] = "Bandit"
HEX_CODES[0xEDFC] = "Bandit"
HEX_CODES[0xEE30] = "Natalie" -- (thumbnail only)
HEX_CODES[0xEE64] = "Bool"
HEX_CODES[0xEE98] = "Bandit"
HEX_CODES[0xEECC] = "Bandit"
HEX_CODES[0xEF00] = "Bandit"
HEX_CODES[0xEF34] = "Bandit"
HEX_CODES[0xEF68] = "Bandit"
HEX_CODES[0xEF9C] = "Bandit"
HEX_CODES[0xEFD0] = "Heintz"
HEX_CODES[0xF004] = "Black Fang"
HEX_CODES[0xF038] = "Black Fang"
HEX_CODES[0xF06C] = "Black Fang"
HEX_CODES[0xF0A0] = "Black Fang"
HEX_CODES[0xF0D4] = "Black Fang"
HEX_CODES[0xF108] = "Black Fang"
HEX_CODES[0xF13C] = "Beyard"
HEX_CODES[0xF170] = "Black Fang"
HEX_CODES[0xF1A4] = "Black Fang"
HEX_CODES[0xF1D8] = "Black Fang"
HEX_CODES[0xF20C] = "Black Fang"
HEX_CODES[0xF240] = "Black Fang"
HEX_CODES[0xF274] = "Black Fang"
HEX_CODES[0xF2A8] = "Black Fang"
HEX_CODES[0xF2DC] = "Black Fang"
HEX_CODES[0xF310] = "Yogi"
HEX_CODES[0xF344] = "Caelin"
HEX_CODES[0xF378] = "Caelin"
HEX_CODES[0xF3AC] = "Caelin"
HEX_CODES[0xF3E0] = "Caelin"
HEX_CODES[0xF414] = "Caelin"
HEX_CODES[0xF448] = "Caelin"
HEX_CODES[0xF47C] = "Caelin"
HEX_CODES[0xF4B0] = "Eagler"
HEX_CODES[0xF4E4] = "Caelin"
HEX_CODES[0xF518] = "Caelin"
HEX_CODES[0xF54C] = "Caelin"
HEX_CODES[0xF580] = "Caelin"
HEX_CODES[0xF5B4] = "Caelin"
HEX_CODES[0xF5E8] = "Caelin"
HEX_CODES[0xF61C] = "Lundgren"
HEX_CODES[0xF650] = "Caelin"
HEX_CODES[0xF684] = "Caelin"
HEX_CODES[0xF6B8] = "Caelin"
HEX_CODES[0xF6EC] = "Caelin"
HEX_CODES[0xF720] = "Caelin"
HEX_CODES[0xF754] = "Caelin"
HEX_CODES[0xF788] = "Caelin"
HEX_CODES[0xF7BC] = "Tactician"
HEX_CODES[0xF7F0] = "Citizen"
HEX_CODES[0xF824] = "Citizen"
HEX_CODES[0xF858] = "Citizen"
HEX_CODES[0xF88C] = "Citizen"
HEX_CODES[0xF8C0] = "Citizen"
HEX_CODES[0xF8F4] = "Citizen"
HEX_CODES[0xF928] = "Citizen"
HEX_CODES[0xF95C] = "Citizen"
HEX_CODES[0xF990] = "Citizen"
HEX_CODES[0xF9C4] = "Merc"
HEX_CODES[0xF9F8] = "Pirate"
HEX_CODES[0xFA2C] = "Bandit"
HEX_CODES[0xFA60] = "Citizen"
HEX_CODES[0xFA94] = "Citizen"
HEX_CODES[0xFAC8] = "Citizen"
HEX_CODES[0xFAFC] = "Black Fang"
HEX_CODES[0xFB30] = "Black Fang"
HEX_CODES[0xFB64] = "Bandit"
HEX_CODES[0xFB98] = "Black Fang"
HEX_CODES[0xFBCC] = "Morph"
HEX_CODES[0xFC00] = "Black Fang"
HEX_CODES[0xFC34] = "Black Fang"
HEX_CODES[0xFC68] = "Bandit"
HEX_CODES[0xFC9C] = "Ostia"
HEX_CODES[0xFCD0] = "Rath's unit"
HEX_CODES[0xFD04] = "Bandit"
HEX_CODES[0xFD38] = "Bandit"
HEX_CODES[0xFD6C] = "Bern"
HEX_CODES[0xFDA0] = "Guardian"
HEX_CODES[0xFDD4] = "Morph"
HEX_CODES[0xFE08] = "Laus"
HEX_CODES[0xFE3C] = "Bandit"
HEX_CODES[0xFE70] = "Bandit"
HEX_CODES[0xFEA4] = "Bern"
HEX_CODES[0xFED8] = "Guardian"
HEX_CODES[0xFF0C] = "Morph"
HEX_CODES[0xFF40] = "Guardian"
HEX_CODES[0xFF74] = "Black Fang"
HEX_CODES[0xFFA8] = "Lloyd" -- (morph)
HEX_CODES[0xFFDC] = "Linus" --  (morph)
	end
	
	if HARD_MODE then
		BASE_STATS[INDEX_OF_NAME["Guy"]]      = {21, 06, 11, 11, 05, 00, 05, 03}
		BASE_STATS[INDEX_OF_NAME["Raven"]]    = {25, 08, 11, 13, 05, 01, 02, 05}
		BASE_STATS[INDEX_OF_NAME["Legault"]]  = {26, 08, 11, 15, 08, 03, 10, 12}
		BASE_STATS[INDEX_OF_NAME["Heath"]]    = {28, 11, 08, 07, 10, 01, 07, 07}
		BASE_STATS[INDEX_OF_NAME["Geitz"]]    = {40, 17, 12, 13, 11, 03, 10, 03}
		BASE_STATS[INDEX_OF_NAME["Harken"]]   = {38, 21, 20, 17, 15, 10, 12, 08}
		BASE_STATS[INDEX_OF_NAME["Vaida"]]    = {43, 20, 19, 13, 21, 06, 11, 09}
	end

	GROWTH_WEIGHTS[INDEX_OF_NAME["Ninian/Nils"]] = {30, 00, 00, 19, 30, 10, 10}	
end

if GAME_VERSION == 8 then
	NAMES = {
	"Eirika", "Seth", "Franz", "Gilliam", "Moulder",
	"Vanessa", "Ross", "Garcia", "Neimi", "Colm",
	"Artur", "Lute", "Natasha", "Joshua", "Ephraim",
	"Forde", "Kyle", "Tana", "Amelia", "Innes",

	"Gerik", "Tethys", "Marisa", "L\'Arachel", "Dozla",
	"Saleh", "Ewan", "Cormag", "Rennac", "Duessel",
	"Knoll", "Myrrh", "Syrene", "Caellach", "Orson",
	"Riev", "Ismaire", "Selena", "Glen", "Hayden",

	"Valter", "Fado", "Lyon"}
	GROWTHS = {
	{70, 40, 60, 60, 30, 30, 60}, --Eirika
	{90, 50, 45, 45, 40, 30, 25}, --Seth
	{80, 40, 40, 50, 25, 20, 40}, --Franz
	{90, 45, 35, 30, 55, 20, 30}, --Gilliam
	{70, 40, 50, 40, 25, 25, 20}, --Moulder
	{50, 35, 55, 60, 20, 30, 50}, --Vanessa
	{70, 50, 35, 30, 25, 20, 40}, --Ross
	{80, 65, 40, 20, 25, 15, 40}, --Garcia
	{55, 45, 50, 60, 15, 35, 50}, --Neimi
	{75, 40, 40, 65, 25, 20, 45}, --Colm
	{55, 50, 50, 40, 15, 55, 25}, --Artur
	{45, 65, 30, 45, 15, 40, 45}, --Lute
	{50, 60, 25, 40, 15, 55, 60}, --Natasha
	{80, 35, 55, 55, 20, 20, 30}, --Joshua
	{80, 55, 55, 45, 35, 25, 50}, --Ephraim
	{85, 40, 50, 45, 20, 25, 35}, --Forde
	{90, 50, 40, 40, 25, 20, 20}, --Kyle
	{65, 45, 40, 65, 20, 25, 60}, --Tana
	{60, 35, 40, 40, 30, 15, 50}, --Amelia
	{75, 40, 40, 45, 20, 25, 45}, --Innes
	{90, 45, 40, 30, 35, 25, 30}, --Gerik
	{85, 05, 10, 70, 30, 75, 80}, --Tethys
	{75, 30, 55, 60, 15, 25, 50}, --Marisa
	{45, 50, 45, 45, 15, 50, 65}, --L’Arachel
	{85, 50, 35, 40, 30, 25, 30}, --Dozla
	{50, 30, 25, 40, 30, 35, 40}, --Saleh
	{50, 45, 40, 35, 15, 40, 50}, --Ewan
	{85, 55, 40, 45, 25, 15, 35}, --Cormag
	{65, 25, 45, 60, 25, 30, 25}, --Rennac
	{85, 55, 40, 30, 45, 30, 20}, --Duessel
	{70, 50, 40, 35, 10, 45, 20}, --Knoll
	{30, 90, 85, 65, 50, 30, 30}, --Myrrh, HP and def +100
	{70, 40, 50, 60, 20, 50, 30}, --Syrene
	{85, 50, 45, 45, 30, 20, 20}, --Caellach
	{80, 55, 45, 40, 45, 30, 25}, --Orson
	{75, 45, 50, 40, 20, 45, 15}, --Riev
	{75, 30, 60, 55, 20, 25, 30}, --Ismaire
	{85, 40, 55, 40, 20, 30, 25}, --Selena
	{85, 45, 50, 45, 35, 40, 20}, --Glen
	{70, 40, 45, 45, 25, 25, 40}, --Hayden
	{80, 40, 55, 50, 20, 20, 15}, --Valter
	{85, 55, 40, 30, 45, 25, 25}, --Fado
	{85, 50, 55, 55, 45, 55, 30}  --Lyon
	}
	BASE_STATS = {
	{16, 04, 08, 09, 03, 01, 05, 01}, --Eirika
	{30, 14, 13, 12, 11, 08, 13, 01}, --Seth
	{20, 07, 05, 07, 06, 01, 02, 01}, --Franz
	{25, 09, 06, 03, 09, 03, 03, 04}, --Gilliam
	{20, 04, 06, 09, 02, 05, 01, 03}, --Moulder
	{17, 05, 07, 11, 06, 05, 04, 01}, --Vanessa
	{15, 05, 02, 03, 03, 00, 08, 01}, --Ross	set base level to -8 after trainee promotion
	{28, 08, 07, 07, 05, 01, 03, 04}, --Garcia
	{17, 04, 05, 06, 03, 02, 04, 01}, --Neimi
	{18, 04, 04, 10, 03, 01, 08, 02}, --Colm
	{19, 06, 06, 08, 02, 06, 02, 02}, --Artur
	{17, 06, 06, 07, 03, 05, 08, 01}, --Lute
	{18, 02, 04, 08, 02, 06, 06, 01}, --Natasha
	{24, 08, 13, 14, 05, 02, 07, 05}, --Joshua
	{23, 08, 09, 11, 07, 02, 08, 04}, --Ephraim
	{24, 07, 08, 08, 08, 02, 07, 06}, --Forde
	{25, 09, 06, 07, 09, 01, 06, 05}, --Kyle
	{20, 07, 09, 13, 06, 07, 08, 04}, --Tana
	{16, 04, 03, 04, 02, 03, 06, 01}, --Amelia	set base level to -8 after trainee promotion
	{31, 14, 13, 15, 10, 09, 14, 01}, --Innes
	{32, 14, 13, 13, 10, 04, 08, 10}, --Gerik
	{18, 01, 02, 12, 05, 04, 10, 01}, --Tethys
	{23, 07, 12, 13, 04, 03, 09, 05}, --Marisa
	{18, 06, 06, 10, 05, 08, 12, 03}, --L’Arachel
	{43, 16, 11, 09, 11, 06, 04, 01}, --Dozla
	{30, 16, 18, 14, 08, 13, 11, 01}, --Saleh
	{15, 03, 02, 05, 00, 03, 05, 01}, --Ewan	set base level to -8 after trainee promotion
	{30, 14, 09, 10, 12, 02, 04, 09}, --Cormag
	{28, 10, 16, 17, 09, 11, 05, 01}, --Rennac
	{41, 17, 12, 12, 17, 09, 08, 08}, --Duessel
	{22, 13, 09, 08, 02, 10, 00, 10}, --Knoll, auto level 1???
	{15, 03, 01, 05, 02, 07, 03, 01}, --Myrrh
	{27, 12, 13, 15, 10, 12, 12, 01}, --Syrene
	{47, 19, 14, 13, 15, 13, 14, 12}, --Caellach
	{48, 18, 15, 14, 14, 11, 06, 13}, --Orson
	{49, 14, 21, 19, 16, 18, 09, 16}, --Riev
	{33, 16, 20, 23, 08, 15, 12, 09}, --Ismaire
	{38, 13, 13, 16, 11, 17, 10, 11}, --Selena
	{46, 20, 17, 13, 18, 05, 07, 12}, --Glen
	{37, 17, 14, 15, 12, 12, 17, 10}, --Hayden
	{45, 19, 17, 17, 13, 12, 03, 13}, --Valter
	{46, 20, 14, 12, 18, 11, 05, 11}, --Fado
	{44, 22, 13, 11, 17, 19, 04, 14}, --Lyon
	}
	BASE_CLASSES = {
	classes.LORD,				--Eirika
	classes.PALADIN_M,			--Seth
	classes.CAVALIER,			--Franz
	classes.ARMOR_KNIGHT,		--Gilliam
	classes.PRIEST,				--Moulder
	classes.PEGASUS_KNIGHT,		--Vanessa
	classes.JOURNEYMAN,			--Ross
	classes.FIGHTER,			--Garcia
	classes.ARCHER,				--Neimi
	classes.THIEF,				--Colm
	classes.MONK,				--Artur
	classes.MAGE,				--Lute
	classes.CLERIC,				--Natasha
	classes.MYRMIDON,			--Joshua
	classes.LORD,				--Ephraim
	classes.CAVALIER,			--Forde
	classes.CAVALIER,			--Kyle
	classes.PEGASUS_KNIGHT,		--Tana
	classes.RECRUIT,			--Amelia
	classes.SNIPER_M,			--Innes
	classes.MERCENARY,			--Gerik
	classes.DANCER,				--Tethys
	classes.MYRMIDON,			--Marisa
	classes.TROUBADOUR,			--L’Arachel
	classes.BERSERKER,			--Dozla
	classes.SAGE_M,				--Saleh
	classes.MAGE,				--Ewan PUPIL
	classes.WYVERN_RIDER,		--Cormag
	classes.ROGUE,				--Rennac
	classes.GREAT_KNIGHT_M,		--Duessel 
	classes.SHAMAN,				--Knoll
	classes.MANAKETE,			--Myrrh
	classes.FALCO_KNIGHT,		--Syrene
	classes.HERO_M,				--Caellach
	classes.PALADIN_M,			--Orson
	classes.BISHOP_M,			--Riev
	classes.SWORDMASTER_F,		--Ismaire
	classes.MAGE_KNIGHT_F,		--Selena
	classes.WYVERN_LORD_M,		--Glen
	classes.TROOPER_M,			--Hayden
	classes.WYVERN_KNIGHT_M,	--Valter
	classes.GENERAL_M,			--Fado
	classes.NECROMANCER			--Lyon
	}
	PROMOTIONS = {
	classes.GREAT_LORD_8_F,		--Eirika
	classes.PALADIN_M,			--Seth
	classes.PALADIN_M,			--Franz
	classes.GREAT_KNIGHT_M,		--Gilliam
	classes.BISHOP_M,			--Moulder SAGE
	classes.WYVERN_KNIGHT_F,	--Vanessa
	classes.BERSERKER,			--Ross
	classes.WARRIOR,			--Garcia HERO
	classes.TROOPER_F, 			--Neimi
	classes.ASSASSIN_M,			--Colm
	classes.BISHOP_M, 			--Artur SAGE
	classes.MAGE_KNIGHT_F, 		--Lute
	classes.VALKYRIE,			--Natasha
	classes.SWORDMASTER_M,		--Joshua
	classes.GREAT_LORD_8_M,		--Ephraim
	classes.PALADIN_M,			--Forde
	classes.PALADIN_M,			--Kyle
	classes.WYVERN_KNIGHT_F, 	--Tana
	classes.PALADIN_F,			--Amelia
	classes.SNIPER_M,			--Innes
	classes.TROOPER_M,			--Gerik HERO
	classes.DANCER,				--Tethys
	classes.SWORDMASTER_F,		--Marisa
	classes.MAGE_KNIGHT_F,		--L’Arachel
	classes.BERSERKER,			--Dozla
	classes.SAGE_M,				--Saleh
	classes.MAGE_KNIGHT_M,		--Ewan
	classes.WYVERN_KNIGHT_M,	--Cormag
	classes.ROGUE,				--Rennac
	classes.GREAT_KNIGHT_M,		--Duessel 
	classes.SUMMONER,			--Knoll
	classes.MANAKETE,			--Myrrh
	classes.FALCO_KNIGHT,		--Syrene
	classes.HERO_M,				--Caellach
	classes.PALADIN_M,			--Orson
	classes.BISHOP_M,			--Riev
	classes.SWORDMASTER_F,		--Ismaire
	classes.MAGE_KNIGHT_F,		--Selena
	classes.WYVERN_LORD_M,		--Glen
	classes.TROOPER_M,			--Hayden
	classes.WYVERN_KNIGHT_M,	--Valter
	classes.GENERAL_M,			--Fado
	classes.NECROMANCER			--Lyon
	}

	initializeCommonValues()
	
	do -- HEX_CODES
HEX_CODES[0x3D64] = "Eirika"
HEX_CODES[0x3D98] = "Seth"
HEX_CODES[0x3DCC] = "Gilliam"
HEX_CODES[0x3E00] = "Franz"
HEX_CODES[0x3E34] = "Moulder"
HEX_CODES[0x3E68] = "Vanessa"
HEX_CODES[0x3E9C] = "Ross"
HEX_CODES[0x3ED0] = "Neimi"
HEX_CODES[0x3F04] = "Colm"
HEX_CODES[0x3F38] = "Garcia"
HEX_CODES[0x3F6C] = "Innes"
HEX_CODES[0x3FA0] = "Lute"
HEX_CODES[0x3FD4] = "Natasha"
HEX_CODES[0x4008] = "Cormag"
HEX_CODES[0x403C] = "Ephraim"
HEX_CODES[0x4070] = "Forde"
HEX_CODES[0x40A4] = "Kyle"
HEX_CODES[0x40D8] = "Amelia"
HEX_CODES[0x410C] = "Artur"
HEX_CODES[0x4140] = "Gerik"
HEX_CODES[0x4174] = "Tethys"
HEX_CODES[0x41A8] = "Marisa"
HEX_CODES[0x41DC] = "Saleh"
HEX_CODES[0x4210] = "Ewan"
HEX_CODES[0x4244] = "L\'Arachel"
HEX_CODES[0x4278] = "Dozla"
HEX_CODES[0x42AC] = "Enemy"
HEX_CODES[0x42E0] = "Rennac"
HEX_CODES[0x4314] = "Duessel"
HEX_CODES[0x4348] = "Myrrh"
HEX_CODES[0x437C] = "Knoll"
HEX_CODES[0x43B0] = "Joshua"
HEX_CODES[0x43E4] = "Syrene"
HEX_CODES[0x4418] = "Tana"
HEX_CODES[0x444C] = "Lyon"
HEX_CODES[0x4480] = "Orson"
HEX_CODES[0x44B4] = "Glen"
HEX_CODES[0x44E8] = "Selena"
HEX_CODES[0x451C] = "Valter"
HEX_CODES[0x4550] = "Riev"
HEX_CODES[0x4584] = "Caellach"
HEX_CODES[0x45B8] = "Fado"
HEX_CODES[0x45EC] = "Ismaire"
HEX_CODES[0x4620] = "Hayden"
	end
	
	BOOSTERS[INDEX_OF_NAME["Lute"]] = {0, 0, 2, 0, 2, 0, 0}
	BOOSTERS[INDEX_OF_NAME["Tana"]] = {7, 0, 0, 0, 2, 0, 0}
	BOOSTERS[INDEX_OF_NAME["Dozla"]] = {0, 0, 2, 2, 0, 0, 2}
	
	PROMOTED_AT[INDEX_OF_NAME["Franz"]] = 17
	PROMOTED_AT[INDEX_OF_NAME["Lute"]] = 15
	PROMOTED_AT[INDEX_OF_NAME["Gerik"]] = 10
	
	GROWTH_WEIGHTS[INDEX_OF_NAME["L\'Arachel"]] = {30, 60, 05, 19, 30, 10, 10}
	GROWTH_WEIGHTS[INDEX_OF_NAME["Tethys"]] = {30, 00, 00, 19, 30, 10, 10}

--	BOOSTERS[INDEX_OF_NAME["Ewan"]] = {1, 0, 1, 2, 1, 2, 0} -- Mage promo, set base lvl to -8
end

-- for unfound hex codes
NAMES[0] = "unit not found"
GROWTHS[0] = {0, 0, 0, 0, 0, 0, 0}
GROWTH_WEIGHTS[0] = {0, 0, 0, 0, 0, 0, 0}
BASE_STATS[0] = {0, 0, 0, 0, 0, 0, 0, 0}
BOOSTERS[0] = {0, 0, 0, 0, 0, 0, 0}
BASE_CLASSES[0] = classes.OTHER
PROMOTIONS[0] = classes.OTHER_PROMOTED 
PROMOTED_AT[0] = 0
WILL_PROMOTE_AT[0] = 0
WILL_END_AT[0] = 0

-- determine if healer is present manually
P.HEALER_DEPLOYED = false
 



local function statsInRAM()
	local stats = {}
	
	stats[1] = memory.readbyte(addr.ATTACKER_START + addr.MAX_HP_OFFSET)
	for stat_i = 2, 7 do
		stats[stat_i] = memory.readbyte(addr.ATTACKER_START + addr.MAX_HP_OFFSET + stat_i)  -- at +1 is current hp
	end
	stats[LEVEL_I] = memory.readbyte(addr.ATTACKER_START + addr.LEVEL_OFFSET)
	stats[EXP_I] = memory.readbyte(addr.ATTACKER_START + addr.EXP_OFFSET)
	
	return stats
end

function P.hexCodeToName(hexCode)
	return HEX_CODES[hexCode] or string.format("%04X", hexCode)
end

local RANK_NAMES = {"Sword", "Lance", "Axe", "Bow", "Staff", "Anima", "Light", "Dark"}
function P.printRanks()
	for i, name in ipairs(RANK_NAMES) do
		local rank = memory.readbyte(addr.ATTACKER_START + addr.RANKS_OFFSET + i - 1)
		if rank > 0 then
			print(name .. " rank " .. rank)
		end
	end
end

function P.printSupports()
	for i = 0, 9 do
		local support = memory.readbyte(addr.ATTACKER_START + addr.SUPPORTS_OFFSET + i)
		if support > 0 then
			print("Support " .. i .. " " .. support)
		end
	end
end




local function factorial(x)
	if x <= 1 then return 1 end
	return x * factorial(x-1)
end

local function binomialDistrib(numSuccesses, numTrials, p)
	local numFails = numTrials - numSuccesses
	
	local choose = factorial(numTrials)/(factorial(numSuccesses)*factorial(numFails))
	
	return choose * (p^numSuccesses) * (1-p)^numFails
end

-- probability of S or fewer successes in T attempts
local function cumulativeBinDistrib(numSuccesses, numTrials, p)
	if numSuccesses >= numTrials then return 1 end

	local ret = 0
	for i = 0, numSuccesses do
		ret = ret + binomialDistrib(i, numTrials, p)
	end	
	return ret
end

local function percentile(numSuccesses, numTrials, p)
	-- treat half of same number of successes as below and half as above
	return cumulativeBinDistrib(numSuccesses - 1, numTrials, p) +
			binomialDistrib(numSuccesses, numTrials, p)/2
end




local unitObj = {}

-- non modifying functions

function unitObj:willLevelStats(HP_RN_i)
	ret = {}
	for stat_i, growth in ipairs(self.growths) do
		if self.stats[stat_i] >= classes.CAPS[self.class][stat_i] then
			ret[stat_i] = -1 -- stat capped
		elseif rns.rng1:getRN(HP_RN_i+stat_i-1) < growth then
			ret[stat_i] = 1 -- stat grows without afa's
		elseif rns.rng1:getRN(HP_RN_i+stat_i-1) < growth + 5 and self.hasAfas then
			ret[stat_i] = 2 -- stat grows because of afa's
		elseif rns.rng1:getRN(HP_RN_i+stat_i-1) < growth + 5 and GAME_VERSION > 6 then
			ret[stat_i] = -2 -- stat would grow with afa's
		else
			ret[stat_i] = 0 -- stat doesn't grow
		end
	end
	return ret
end

function unitObj:levelUpProcs_string(HP_RN_i)
	local seq = ""
	local noStatWillRise = true
	local noStatIsCapped = true

	for _, proc in ipairs(self:willLevelStats(HP_RN_i)) do		
		if proc == 1 then
			seq = seq .. "+" -- grows this stat
			noStatWillRise = false
		elseif proc == 2 then
			seq = seq .. "!" -- grows this stat because of Afa's
			noStatWillRise = false
		elseif proc == -2 and addr.canAddAfas then
			seq = seq .. "?" -- stat would grow with afa's
		elseif proc == -1 then
			seq = seq .. "_" -- can't grow stat
			noStatIsCapped = false
		else
			seq = seq .. "."
		end
	end
	if noStatWillRise and noStatIsCapped then
		seq = seq .. " EMPTY, may proc more RNs!" 
		-- todo how does this work?
		-- continue rolling, one rn at a time, until a stat grows?
	end
	return seq
end

-- gets score for level up starting at rns index HP_RN_i
-- scored such that average level is 0, empty level is -100 exp
-- empty level wipes out value of exp used to level up
function unitObj:levelScoreInExp(HP_RN_i)
	if self.avgLevelValue == 0 then return 0 end
	
	local procs = self:willLevelStats(HP_RN_i)
	
	local score = 0
	for stat_i = 1, 7 do
		if procs[stat_i] > 0 then
			score = score + self.dynamicWeights[stat_i]
		end
	end
	score = score * 100
	
	score = score - self.avgLevelValue -- score now ranges [-avg, perf-avg]
	
	return 100*score/self.avgLevelValue
end

function unitObj:expValueFactor()
	return self.avgLevelValue/EXP_VALUE_FACTOR_SCALE
end

-- works for levels too
function unitObj:statsGained(stat_i)
	return self.stats[stat_i] - self.bases[stat_i]
end

function unitObj:statAverage(stat_i)
	return self.bases[stat_i] + self:statsGained(LEVEL_I)*self.growths[stat_i]/100
end

function unitObj:statDeviation(stat_i)
	return self.stats[stat_i] - self:statAverage(stat_i)
end

-- how many sigma's off from average
function unitObj:statStdDev(stat_i)
	local growthProb = self.growths[stat_i]/100
	
	local stdDev = (self:statsGained(LEVEL_I)*growthProb*(1-growthProb))^0.5
	
	if stdDev == 0 then return 0 end
	
	return self:statDeviation(stat_i)/stdDev
end

function unitObj:effectiveGrowthRate(stat_i)
	if self:statsGained(LEVEL_I) == 0 then return 0 end
	
	return 100*self:statsGained(stat_i)/self:statsGained(LEVEL_I)
end

function unitObj:statData_strings(showPromo)
	showPromo = (showPromo and self.canPromote)
	
	local statHeader = string.format("%-10.10s      Hp St Sk Sp Df Rs Lk", self.name)
	
	local baseStr       = "Base + boost   "
	local statStr       = "Stat at " .. string.format("%2d.%02d  ", self.stats[LEVEL_I], self.stats[EXP_I])
	if self.stats[EXP_I] == 255 then
		statStr         = "Stat at " .. string.format("%2d.--  ", self.stats[LEVEL_I])
	end
	local capStr        = "Cap            "
	if showPromo then
		statStr         = "Stat at PROMO  "
		capStr          = "Cap     PROMO  "
	end
	
	local weightStr     = "Weight   " .. string.format(" x%4.2f", self:expValueFactor())
	local growthStr     = "Growth         "
	if self.hasAfas then
		growthStr       = "Growth +Afa's  "
	end
	local trueGrowthStr = "Actual Growth  "
	local percentileStr = "Percentile     "
	local stndDevStr    = "Standard Dev   "
	
	local twoDigits = " %02d"
	for stat_i = 1, 7 do
		baseStr = baseStr .. twoDigits:format(self.bases[stat_i])
		
		if showPromo then
			statStr = statStr .. twoDigits:format(self.stats[stat_i] 
					+ classes.PROMO_GAINS[self.promotion][stat_i])
			capStr = capStr .. twoDigits:format(classes.CAPS[self.promotion][stat_i])
		else
			statStr = statStr .. twoDigits:format(self.stats[stat_i])
			capStr = capStr .. twoDigits:format(classes.CAPS[self.class][stat_i])
		end
		
		weightStr = weightStr .. twoDigits:format(self.dynamicWeights[stat_i])
		
		if self:effectiveGrowthRate(stat_i) < 100 then
			trueGrowthStr = trueGrowthStr .. twoDigits:format(self:effectiveGrowthRate(stat_i))
		else
			trueGrowthStr = trueGrowthStr .. " A0"
		end
		
		local growth = self.growths[stat_i]
		if self.hasAfas then
			growth = growth + 5
		end
		
		growthStr = growthStr .. twoDigits:format(growth)
		
		percentileStr = percentileStr .. twoDigits:format(
			100*percentile(self:statsGained(stat_i), self:statsGained(LEVEL_I), growth/100))
		
		local stdDv = self:statStdDev(stat_i)
		stndDevStr = stndDevStr .. string.format("%+03d", 10*stdDv)
	end
	
	return {statHeader, baseStr, statStr, capStr, weightStr, growthStr, trueGrowthStr, percentileStr}
end





-- modifying functions

function unitObj:toggleAfas()
	local str = "Afa's "
	if GAME_VERSION == 8 then
		str = "Metis "
	end

	if self.hasAfas then
		str = str .. "removed from "
	else
		str = str .. "applied to "
	end
	print(str .. self.name)
	
	self.hasAfas = not self.hasAfas
end

-- adjusts preset stat weights downward when stat is likely to cap
function unitObj:setDynamicWeights()
	self.dynamicWeights = {0, 0, 0, 0, 0, 0, 0}
	if self.stats[LEVEL_I] >= 20 then return end
	
	local levelsTilEnd = self.willEndAt - self.stats[LEVEL_I]
	if self.canPromote then
		levelsTilEnd = self.willPromoteAt - self.stats[LEVEL_I]
	end
	
	for stat_i = 1, 7 do
		local gainsTilStatCap = classes.CAPS[self.class][stat_i] - self.stats[stat_i]
		
		-- multiply by 1 - P(reaching/exceeding cap even if not gaining stat this level)
		-- if no chance to reach cap if not leveling, full weight
		-- if 100% chance (ie at cap), no weight
		
		-- 1 - P(reaching/exceeding cap | not gaining stat this level) =
		-- 1 - (1 - P(less than cap | gained levelsTilEnd - 1 levels)) =
		-- P(less than cap | gained levelsTilEnd - 1 levels)
		
		local probWontReachCapIfNotGaining = 
			cumulativeBinDistrib(gainsTilStatCap-1, levelsTilEnd-1, self.growths[stat_i]/100)
		
		-- if more likely to hit promoted class cap than unpromoted, use that probability
		if self.canPromote then
			local gainsTilStatCap_P = classes.CAPS[self.promotion][stat_i] 
				- self.stats[stat_i] - classes.PROMO_GAINS[self.promotion][stat_i]
			
			-- may need levels to even reach promotion
			local levelsTilEnd_P = self.willEndAt - 1 + math.max(self.willPromoteAt - self.stats[LEVEL_I], 0)
			
			local probWontReachCapIfNotGaining_P = 
				cumulativeBinDistrib(gainsTilStatCap_P-1, levelsTilEnd_P-1, self.growths[stat_i]/100)
				
			if probWontReachCapIfNotGaining > probWontReachCapIfNotGaining_P then
				probWontReachCapIfNotGaining = probWontReachCapIfNotGaining_P
			end
		end
		
		self.dynamicWeights[stat_i] = self.growthWeights[stat_i] * probWontReachCapIfNotGaining
	end
end

function unitObj:loadRAMvalues()
	self.class = classes.HEX_CODES[memory.readword(addr.ATTACKER_START + addr.CLASS_CODE_OFFSET)] or classes.OTHER
	self.canPromote = self.class == BASE_CLASSES[unit_i] and self.class ~= self.promotion
	if self.canPromote then
		for i, gain in ipairs(classes.PROMO_GAINS[self.class]) do
			self.bases[i] = self.bases[i] + gain
		end
		self.bases[LEVEL_I] = 1 + BASE_STATS[unit_i][LEVEL_I] - PROMOTED_AT[unit_i]
	end
	
	self.stats = statsInRAM()
	
	self:setDynamicWeights()
	
	self.avgLevelValue = 0
	for i = 1, 7 do
		self.avgLevelValue = self.avgLevelValue + self.growths[i]*self.dynamicWeights[i]
	end
	
	self.hasAfas = addr.unitHasAfas(addr.ATTACKER_START) -- todo incorporate phase
end

function unitObj:new(unit_i)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	
	o.name = NAMES[unit_i]
	o.growths = GROWTHS[unit_i]
	o.growthWeights = GROWTH_WEIGHTS[unit_i]
	
	o.bases = BASE_STATS[unit_i]
	for i, boost in ipairs(BOOSTERS[unit_i]) do
		o.bases[i] = o.bases[i] + boost
	end

	o.promotion = PROMOTIONS[unit_i]
	o.willPromoteAt = WILL_PROMOTE_AT[unit_i]
	o.willEndAt = WILL_END_AT[unit_i]
	
	o:loadRAMvalues()
	
	return o
end

local units = {}
for unit_i = 1, #NAMES do
	table.insert(units, unitObj:new(unit_i))
end
units[0] = unitObj:new(0)

function P.currUnit()
	local nameCode = memory.readword(addr.ATTACKER_START + addr.NAME_CODE_OFFSET)
	if getPhase() == "enemy" then
		nameCode = memory.readword(addr.DEFENDER_START + addr.NAME_CODE_OFFSET)
	end
	local name = P.hexCodeToName(nameCode)
	
	local u = units[0]
	if INDEX_OF_NAME[name] then
		u = units[INDEX_OF_NAME[name]]
	else
		print(string.format("unit not found %s %0X", name, nameCode))
		INDEX_OF_NAME[name] = 0 -- will "find" unit 0 if checking for this code again
	end
	
	u:loadRAMvalues()
	
	return u
end

return unitData
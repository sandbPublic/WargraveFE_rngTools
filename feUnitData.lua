require("feRandomNumbers")
require("feClass")
require("feCombat")
require("feVersion")

local P = {}
unitData = P

-- luck is in the wrong place relative to what is shown on screen:
P.STAT_NAMES = {"HP", "Str", "Skl", "Spd", "Def", "Res", "Lck", "Lvl", "Exp"}

P.LUCK_I = 7
P.LEVEL_I = 8
P.EXP_I = 9

P.NUM_OF_UNITS = {}
P.NAMES = {}
P.DEPLOYED = {}
P.GROWTHS = {}
P.GROWTH_WEIGHTS = {}
P.BASE_STATS = {} -- store base stats, names, deployed, and classes in one table?
P.BASE_STATS_HM = {} -- hard mode
P.BOOSTERS = {}
P.CLASSES = {}
P.PROMOTIONS = {}
P.PROMOTED_AT = {}

local indexer = 0
local function nextInd()
	indexer = indexer + 1
	return indexer
end

local ROY = nextInd()
local MARCUS = nextInd()
local ALLEN = nextInd()
local LANCE = nextInd()
local WOLT = nextInd()
local BORS = nextInd()
local MERLINUS = nextInd()
local ELLEN = nextInd()
local DIECK = nextInd()
local WADE  = nextInd()
local LOTT = nextInd()
local SHANNA = nextInd()
local CHAD = nextInd()
local LUGH = nextInd()
local CLARINE = nextInd()
local RUTGER = nextInd()
local SAUL = nextInd()
local DOROTHY = nextInd()
local SUE = nextInd()
local ZEALOT = nextInd()
local TRECK = nextInd()
local NOAH = nextInd()
local ASTOHL = nextInd()
local LILINA = nextInd()
local WENDY = nextInd()
local BARTH = nextInd()
local OUJAY = nextInd()
local FIR = nextInd()
local SHIN = nextInd()
local GONZALES = nextInd()
local GEESE = nextInd()
local KLEIN = nextInd()
local TATE = nextInd()
local LALUM = nextInd()
local ECHIDNA = nextInd()
local ELPHIN = nextInd()
local BARTRE = nextInd()
local RAY = nextInd()
local CATH = nextInd()
local MIREDY = nextInd()
local PERCIVAL = nextInd()
local CECILIA = nextInd()
local SOFIYA = nextInd()
local IGRENE = nextInd()
local GARRET = nextInd()
local FA = nextInd()
local HUGH = nextInd()
local ZEIS = nextInd()
local DOUGLAS = nextInd()
local NIIME = nextInd()
local DAYAN = nextInd()
local JUNO = nextInd()
local YODEL = nextInd()
local KAREL = nextInd()

P.NUM_OF_UNITS[6] = indexer
P.NAMES[6] = {
"Roy", "Marcus", "Allen", "Lance", "Wolt", 
"Bors", "Merlinus", "Ellen", "Dieck", "Wade", 
"Lott", "Shanna", "Chad", "Lugh", "Clarine", 
"Rutger", "Saul", "Dorothy", "Sue", "Zealot",
 
"Treck", "Noah", "Astore", "Lilina", "Wendy", 
"Barth", "Ogier", "Fir", "Shin", "Gonzales", 
"Geese", "Klein", "Tate", "Lalum", "Echidna", 
"Elphin", "Bartre", "Ray", "Cath", "Milady", 

"Percival", "Cecilia", "Sophia", "Igrene", "Garret", 
"Fa", "Hugh", "Zeis", "Douglas", "Niime", 
"Dayan", "Juno", "Yodel", "Karel"}
P.GROWTHS[6] = {
{80, 40, 50, 40, 25, 30, 60}, -- Roy
{60, 25, 20, 25, 15, 20, 20}, -- Marcus
{85, 45, 40, 45, 25, 10, 40}, -- Allen
{80, 40, 45, 50, 20, 15, 35}, -- Lance
{80, 40, 50, 40, 20, 10, 40}, -- Wolt
{90, 30, 30, 40, 35, 10, 50}, -- Bors
{00, 00, 50, 50, 20, 05, 00}, -- Merlinus
{45, 50, 30, 20, 05, 60, 70}, -- Ellen
{90, 40, 40, 30, 20, 15, 35}, -- Dieck
{75, 50, 45, 20, 30, 05, 45}, -- Wade 
{80, 30, 30, 35, 40, 15, 30}, -- Lott
{45, 30, 55, 60, 10, 25, 60}, -- Shanna
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
{70, 40, 20, 30, 20, 05, 20}, -- Bartre
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
{10, 30, 40, 40, 10, 00, 20}  -- Karel
}
P.BASE_STATS[6] = {
{18, 05, 05, 07, 07, 05, 00, 01}, -- Roy
{32, 09, 14, 11, 10, 09, 08, 01}, -- Marcus
{21, 07, 04, 06, 03, 06, 00, 01}, -- Allen
{20, 05, 06, 08, 02, 06, 00, 01}, -- Lance
{18, 04, 04, 05, 02, 04, 00, 01}, -- Wolt
{20, 07, 04, 03, 04, 11, 00, 01}, -- Bors
{15, 00, 03, 03, 10, 03, 00, 01}, -- Merlinus
{16, 01, 06, 08, 08, 00, 06, 02}, -- Ellen
{26, 09, 12, 10, 05, 06, 01, 05}, -- Dieck
{28, 08, 03, 05, 04, 03, 00, 02}, -- Wade
{29, 07, 06, 07, 02, 04, 01, 03}, -- Lott
{17, 04, 06, 12, 05, 06, 05, 01}, -- Thany
{16, 03, 03, 10, 04, 02, 00, 01}, -- Chad
{16, 04, 05, 06, 05, 03, 05, 01}, -- Lugh
{15, 02, 05, 09, 08, 02, 05, 01}, -- Clarine
{22, 07, 12, 13, 02, 05, 00, 04}, -- Rutger
{20, 04, 06, 10, 02, 02, 05, 05}, -- Saul
{19, 05, 06, 06, 03, 04, 02, 03}, -- Dorothy
{18, 05, 07, 08, 04, 05, 00, 01}, -- Sue
{35, 10, 12, 13, 05, 11, 07, 01}, -- Zealot
{25, 08, 06, 07, 05, 08, 00, 04}, -- Treck
{27, 08, 07, 09, 06, 07, 01, 07}, -- Noah
{25, 07, 08, 15, 11, 07, 03, 10}, -- Astohl
{16, 05, 05, 04, 04, 02, 07, 01}, -- Lilina
{19, 04, 03, 03, 06, 08, 01, 01}, -- Wendy
{25, 10, 06, 05, 02, 14, 01, 09}, -- Barth
{24, 07, 10, 09, 06, 04, 00, 03}, -- Oujay
{19, 06, 09, 10, 03, 03, 01, 01}, -- Fir
{24, 07, 08, 10, 06, 07, 00, 05}, -- Shin
{36, 12, 05, 09, 05, 06, 00, 05}, -- Gonzales
{33, 10, 09, 09, 09, 08, 00, 10}, -- Geese
{27, 13, 13, 11, 10, 08, 06, 01}, -- Klein
{22, 06, 08, 11, 03, 07, 06, 08}, -- Tate
{14, 01, 02, 11, 09, 02, 04, 01}, -- Lalum
{35, 13, 19, 18, 06, 08, 07, 01}, -- Echidna
{15, 01, 03, 10, 11, 04, 01, 01}, -- Elphin
{48, 22, 11, 10, 14, 10, 03, 01}, -- Bartre
{23, 12, 09, 09, 06, 05, 10, 12}, -- Ray
{16, 03, 07, 11, 08, 02, 01, 05}, -- Cath
{30, 12, 11, 10, 05, 13, 03, 10}, -- Miredy
{43, 17, 13, 18, 12, 14, 11, 05}, -- Percival
{30, 11, 07, 10, 10, 07, 13, 01}, -- Cecilia
{15, 06, 02, 04, 03, 01, 08, 01}, -- Sofiya
{32, 16, 18, 15, 09, 11, 10, 01}, -- Igrene
{49, 17, 13, 10, 12, 09, 04, 01}, -- Garret
{16, 02, 02, 03, 07, 02, 06, 01}, -- Fa
{26, 13, 11, 12, 10, 09, 09, 15}, -- Hugh
{28, 14, 09, 08, 06, 12, 02, 07}, -- Zeis
{46, 19, 13, 08, 11, 20, 05, 08}, -- Douglas
{25, 21, 20, 16, 15, 05, 18, 18}, -- Niime
{43, 14, 16, 20, 12, 10, 12, 12}, -- Dayan
{33, 11, 14, 16, 14, 08, 12, 09}, -- Juno
{35, 19, 18, 14, 11, 05, 30, 20}, -- Yodel
{44, 20, 28, 23, 18, 15, 13, 19}  -- Karel
}
-- hard mode bases?
P.CLASSES[6] = {
classes.M.LORD, 			-- Roy
classes.M.PALADIN, 			-- Marcus
classes.M.CAVALIER, 		-- Allen
classes.M.CAVALIER, 		-- Lance
classes.M.ARCHER, 			-- Wolt 
classes.M.ARMOR_KNIGHT, 	-- Bors 
classes.M.TRANSPORTER, 		-- Merlinus
classes.F.CLERIC, 			-- Ellen
classes.M.MERCENARY, 		-- Dieck
classes.M.FIGHTER, 			-- Wade
classes.M.FIGHTER, 			-- Lott
classes.F.PEGASUS_KNIGHT, 	-- Thany
classes.M.THIEF, 			-- Chad
classes.M.MAGE, 			-- Lugh
classes.F.TROUBADOUR, 		-- Clarine 
classes.M.MYRMIDON, 		-- Rutger 
classes.M.CLERIC, 			-- Saul
classes.F.ARCHER, 			-- Dorothy 
classes.F.NOMAD, 			-- Sue 
classes.M.PALADIN, 			-- Zealot
classes.M.CAVALIER, 		-- Treck
classes.M.CAVALIER, 		-- Noah
classes.M.THIEF, 			-- Astohl
classes.F.MAGE, 			-- Lilina
classes.F.ARMOR_KNIGHT, 	-- Wendy
classes.M.ARMOR_KNIGHT, 	-- Barth
classes.M.MERCENARY, 		-- Oujay
classes.F.MYRMIDON, 		-- Fir
classes.M.NOMAD, 			-- Shin
classes.M.BRIGAND, 			-- Gonzales
classes.M.PIRATE, 			-- Geese
classes.M.SNIPER, 			-- Klein
classes.F.PEGASUS_KNIGHT, 	-- Tate
classes.F.DANCER, 			-- Lalum
classes.F.HERO, 			-- Echidna
classes.M.BARD, 			-- Elphin
classes.M.WARRIOR, 			-- Bartre
classes.M.SHAMAN, 			-- Ray
classes.F.THIEF, 			-- Cath
classes.F.WYVERN_RIDER, 	-- Miredy 
classes.M.PALADIN, 			-- Percival
classes.F.VALKYRIE, 		-- Cecilia
classes.F.SHAMAN, 			-- Sofiya
classes.F.SNIPER, 			-- Igrene
classes.M.BERSERKER, 		-- Garret
classes.F.MANAKETE, 		-- Fa
classes.M.MAGE, 			-- Hugh
classes.M.WYVERN_RIDER, 	-- Zeis
classes.M.GENERAL, 			-- Douglas
classes.F.DRUID, 			-- Niime
classes.M.RANGER, 			-- Dayan
classes.F.FALCO_KNIGHT, 	-- Juno
classes.M.BISHOP, 			-- Yodel
classes.M.SWORDMASTER 		-- Karel
}
P.PROMOTIONS[6] = {
classes.M.MASTER_LORD, 		-- Roy
classes.M.PALADIN, 			-- Marcus
classes.M.PALADIN, 			-- Allen
classes.M.PALADIN, 			-- Lance
classes.M.SNIPER, 			-- Wolt
classes.M.GENERAL, 			-- Bors
classes.M.TRANSPORTER, 		-- Merlinus
classes.F.BISHOP, 			-- Ellen
classes.M.HERO, 			-- Dieck
classes.M.WARRIOR, 			-- Wade
classes.M.WARRIOR, 			-- Lott
classes.F.FALCO_KNIGHT, 	-- Thany
classes.M.THIEF, 			-- Chad
classes.M.SAGE, 			-- Lugh
classes.F.VALKYRIE, 		-- Clarine
classes.M.SWORDMASTER, 		-- Rutger
classes.M.BISHOP, 			-- Saul
classes.F.SNIPER, 			-- Dorothy
classes.F.RANGER, 			-- Sue
classes.M.PALADIN, 			-- Zealot
classes.M.PALADIN, 			-- Treck
classes.M.PALADIN, 			-- Noah
classes.M.THIEF, 			-- Astohl
classes.F.SAGE, 			-- Lilina
classes.F.GENERAL, 			-- Wendy
classes.M.GENERAL, 			-- Barth
classes.M.HERO, 			-- Oujay
classes.F.SWORDMASTER, 		-- Fir
classes.M.RANGER, 			-- Shin 
classes.M.BERSERKER, 		-- Gonzales
classes.M.BERSERKER, 		-- Geese
classes.M.SNIPER, 			-- Klein
classes.F.FALCO_KNIGHT, 	-- Tate
classes.F.DANCER, 			-- Lalum
classes.F.HERO, 			-- Echidna
classes.M.BARD, 			-- Elphin
classes.M.WARRIOR, 			-- Bartre
classes.M.DRUID, 			-- Ray
classes.F.THIEF, 			-- Cath
classes.F.WYVERN_LORD, 		-- Miredy
classes.M.PALADIN, 			-- Percival
classes.F.VALKYRIE, 		-- Cecilia
classes.F.DRUID, 			-- Sofiya
classes.F.SNIPER, 			-- Igrene
classes.M.BERSERKER, 		-- Garret
classes.F.MANAKETE, 		-- Fa
classes.M.SAGE, 			-- Hugh
classes.M.WYVERN_LORD, 		-- Zeis
classes.M.GENERAL, 			-- Douglas
classes.F.DRUID, 			-- Niime
classes.M.RANGER, 			-- Dayan
classes.F.FALCO_KNIGHT, 	-- Juno
classes.M.BISHOP, 			-- Yodel
classes.M.SWORDMASTER 		-- Karel
}

P.DEPLOYED[6] = {}
P.BOOSTERS[6] = {}
P.GROWTH_WEIGHTS[6] = {}
for unit_i = 1, P.NUM_OF_UNITS[6] do
	P.GROWTH_WEIGHTS[6][unit_i] = {20, 40, 20, 50, 30, 10, 10}
	-- speed>str>def>skl=hp>res=luck
	P.BOOSTERS[6][unit_i] = {0, 0, 0, 0, 0, 0, 0, 0}
end

P.DEPLOYED[6][ROY] = true
P.GROWTH_WEIGHTS[6][LALUM] = {30, 00, 00, 20, 20, 10, 10} -- ideally won't take more than 1 hit anyway
P.GROWTH_WEIGHTS[6][ELPHIN] = {30, 00, 00, 20, 20, 10, 10}

P.PROMOTED_AT[6] = {
 0,  0,  0,  0,  0, -- Roy Marcus Allen Lance Wolt
 0,  0,  0,  0,  0, -- Bors Merlinus Ellen Dieck Wade 
 0,  0,  0,  0,  0, -- Lott Shanna Chad Lugh Clarine
 0,  0,  0,  0,  0, -- Rutger Saul Dorothy Sue Zealot
 0,  0,  0,  0,  0, -- Treck Noah Astore Lilina Wendy
 0,  0,  0,  0,  0, -- Barth Ogier Fir Shin Gonzales
 0,  0,  0,  0,  0, -- Geese Klein Tate Lalum Echidna
 0,  0,  0,  0,  0, -- Elphin Bartre Ray Cath Milady
 0,  0,  0,  0,  0, -- Percival Cecilia Sophia Igrene Garret 
 0,  0,  0,  0,  0, -- Fa Hugh Zeis Douglas Niime
 0,  0,  0,  0      -- Dayan Juno Yodel Karel
}

indexer = 0
local ELIWOOD = nextInd()
local LOWEN = nextInd()
local MARCUS = nextInd()
local REBECCA = nextInd()
local DORCAS = nextInd()
local BARTRE = nextInd()
local HECTOR = nextInd()
local OSWIN = nextInd()
local SERRA = nextInd()
local MATTHEW = nextInd()
local GUY = nextInd()
local MERLINUS = nextInd()
local ERK = nextInd()
local PRISCILLA = nextInd()
local LYN = nextInd()
local WIL = nextInd()
local KENT = nextInd()
local SAIN = nextInd()
local FLORINA = nextInd()
local RAVEN = nextInd()
local LUCIUS = nextInd()
local CANAS = nextInd()
local DART = nextInd()
local FIORA = nextInd()
local LEGAULT = nextInd()
local NINIAN_NILS = nextInd()
local ISADORA = nextInd()
local HEATH = nextInd()
local RATH = nextInd()
local HAWKEYE = nextInd()
local GEITZ = nextInd()
local WALLACE = nextInd()
local FARINA = nextInd()
local PENT = nextInd()
local LOUISE = nextInd()
local KAREL = nextInd()
local HARKEN = nextInd()
local NINO = nextInd()
local JAFFAR = nextInd()
local VAIDA = nextInd()
local KARLA = nextInd()
local RENAULT = nextInd()
local ATHOS = nextInd()

P.NUM_OF_UNITS[7] = indexer
P.NAMES[7] = {
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
P.GROWTHS[7] = {
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
P.BASE_STATS[7] = {
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
P.BASE_STATS_HM[7] = {
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
{21, 06, 11, 11, 05, 00, 05, 03}, -- Guy	hm									
{18, 00, 04, 05, 05, 02, 12, 05}, -- Merlinus	
{17, 05, 06, 07, 02, 04, 03, 01}, -- Erk	
{16, 06, 06, 08, 03, 06, 07, 03}, -- Priscilla	
{18, 05, 10, 11, 02, 00, 05, 04}, -- Lyn	
{21, 06, 05, 06, 05, 01, 07, 04}, -- Wil	
{23, 08, 07, 08, 06, 01, 04, 05}, -- Kent	
{22, 09, 05, 07, 07, 00, 05, 04}, -- Sain	
{18, 06, 08, 09, 04, 05, 08, 03}, -- Florina	
{25, 08, 11, 13, 05, 01, 02, 05}, -- Raven	hm					
{18, 07, 06, 10, 01, 06, 02, 03}, -- Lucius	
{21, 10, 09, 08, 05, 08, 07, 08}, -- Canas	
{34, 12, 08, 08, 06, 01, 03, 08}, -- Dart	
{21, 08, 11, 13, 06, 07, 06, 07}, -- Fiora	
{26, 08, 11, 15, 08, 03, 10, 12}, -- Legault	hm
{14, 00, 00, 12, 05, 04, 10, 01}, -- Ninian/Nils	
{28, 13, 12, 16, 08, 06, 10, 01}, -- Isadora	
{28, 11, 08, 07, 10, 01, 07, 07}, -- Heath	hm
{27, 09, 10, 11, 08, 02, 05, 09}, -- Rath	
{50, 18, 14, 11, 14, 10, 13, 04}, -- Hawkeye	
{40, 17, 12, 13, 11, 03, 10, 03}, -- Geitz	hm
{34, 16, 09, 08, 19, 05, 10, 01}, -- Wallace	
{24, 10, 13, 14, 10, 12, 10, 12}, -- Farina	
{33, 18, 21, 17, 11, 16, 14, 06}, -- Pent	
{28, 12, 14, 17, 09, 12, 16, 04}, -- Louise	
{31, 16, 23, 20, 13, 12, 15, 08}, -- Karel	
{38, 21, 20, 17, 15, 10, 12, 08}, -- Harken	hm
{19, 07, 08, 11, 04, 07, 10, 05}, -- Nino	
{34, 19, 25, 24, 15, 11, 10, 13}, -- Jaffar	
{43, 20, 19, 13, 21, 06, 11, 09}, -- Vaida	hm	
{29, 14, 21, 18, 11, 12, 16, 05}, -- Karla	
{43, 12, 22, 20, 15, 18, 10, 16}, -- Renault	
{40, 30, 24, 20, 20, 28, 25, 20} -- Athos
}
P.CLASSES[7] = {
classes.M.LORD,			-- Eliwood
classes.M.CAVALIER,		-- Lowen
classes.M.PALADIN,		-- Marcus
classes.F.ARCHER,		-- Rebecca
classes.M.FIGHTER,		-- Dorcas
classes.M.FIGHTER,		-- Bartre
classes.M.LORD,			-- Hector
classes.M.ARMOR_KNIGHT,	-- Oswin
classes.F.CLERIC,		-- Serra
classes.M.THIEF,		-- Matthew
classes.M.MYRMIDON,		-- Guy
classes.M.TRANSPORTER,	-- Merlinus
classes.M.MAGE,			-- Erk
classes.F.TROUBADOUR,	-- Priscilla
classes.F.LORD,			-- Lyn
classes.M.ARCHER,		-- Wil
classes.M.CAVALIER,		-- Kent
classes.M.CAVALIER,		-- Sain
classes.F.PEGASUS_KNIGHT, -- Florina
classes.M.MERCENARY,	-- Raven
classes.M.MONK,			-- Lucius
classes.M.SHAMAN,		-- Canas
classes.M.PIRATE,		-- Dart
classes.F.PEGASUS_KNIGHT, -- Fiora
classes.M.THIEF,		-- Legault
classes.F.DANCER,		-- Ninian/Nils
classes.F.PALADIN,		-- Isadora
classes.M.WYVERN_RIDER,	-- Heath
classes.M.NOMAD,		-- Rath
classes.M.BERSERKER,	-- Hawkeye
classes.M.WARRIOR,		-- Geitz
classes.M.GENERAL,		-- Wallace
classes.F.PEGASUS_KNIGHT, -- Farina
classes.M.SAGE,			-- Pent
classes.F.SNIPER,		-- Louise
classes.M.SWORDMASTER,	-- Karel
classes.M.HERO,			-- Harken
classes.F.MAGE,			-- Nino
classes.M.ASSASSIN,		-- Jaffar
classes.F.WYVERN_LORD,	-- Vaida
classes.F.SWORDMASTER,	-- Karla
classes.M.BISHOP,		-- Renault
classes.M.ARCHSAGE		-- Athos
}
P.PROMOTIONS[7] = {
classes.M.KNIGHT_LORD,	-- Eliwood
classes.M.PALADIN,		-- Lowen
classes.M.PALADIN,		-- Marcus
classes.F.SNIPER,		-- Rebecca
classes.M.WARRIOR,		-- Dorcas
classes.M.WARRIOR,		-- Bartre
classes.M.GREAT_LORD7,	-- Hector
classes.M.GENERAL,		-- Oswin
classes.F.BISHOP,		-- Serra
classes.M.ASSASSIN,		-- Matthew
classes.M.SWORDMASTER,	-- Guy
classes.M.TRANSPORTER,	-- Merlinus
classes.M.SAGE,			-- Erk
classes.F.VALKYRIE,		-- Priscilla
classes.F.BLADE_LORD,	-- Lyn
classes.M.SNIPER,		-- Wil
classes.M.PALADIN,		-- Kent
classes.M.PALADIN,		-- Sain
classes.F.FALCO_KNIGHT, -- Florina
classes.M.HERO,			-- Raven
classes.M.BISHOP,		-- Lucius
classes.M.DRUID,		-- Canas
classes.M.BERSERKER,	-- Dart
classes.F.FALCO_KNIGHT, -- Fiora
classes.M.ASSASSIN,		-- Legault
classes.F.DANCER,		-- Ninian/Nils
classes.F.PALADIN,		-- Isadora
classes.M.WYVERN_LORD,	-- Heath
classes.M.RANGER,		-- Rath
classes.M.BERSERKER,	-- Hawkeye
classes.M.WARRIOR,		-- Geitz
classes.M.GENERAL,		-- Wallace
classes.F.FALCO_KNIGHT, -- Farina
classes.M.SAGE,			-- Pent
classes.F.SNIPER,		-- Louise
classes.M.SWORDMASTER,	-- Karel
classes.M.HERO,			-- Harken
classes.F.SAGE,			-- Nino
classes.M.ASSASSIN,		-- Jaffar
classes.F.WYVERN_LORD,	-- Vaida
classes.F.SWORDMASTER,	-- Karla
classes.M.BISHOP,		-- Renault
classes.M.ARCHSAGE		-- Athos
}

P.DEPLOYED[7] = {}
P.BOOSTERS[7] = {}
P.GROWTH_WEIGHTS[7] = {}
for unit_i = 1, P.NUM_OF_UNITS[7] do
	P.GROWTH_WEIGHTS[7][unit_i] = {20, 40, 20, 50, 30, 10, 10}
	-- speed>str>def>skl=hp>res=luck
	P.BOOSTERS[7][unit_i] = {0, 0, 0, 0, 0, 0, 0, 0}
end

P.DEPLOYED[7][ELIWOOD] = true
P.DEPLOYED[7][REBECCA] = true
P.DEPLOYED[7][HECTOR] = true
P.DEPLOYED[7][GUY] = true
P.DEPLOYED[7][KENT] = true
P.DEPLOYED[7][CANAS] = true
P.DEPLOYED[7][NINIAN_NILS] = true
P.DEPLOYED[7][HEATH] = true
P.DEPLOYED[7][JAFFAR] = true
P.DEPLOYED[7][ATHOS] = true
--P.GROWTH_WEIGHTS[7][21] = {20, 50, 20, 40, 30, 10, 10} -- lucius more mag for warp
--P.GROWTH_WEIGHTS[7][22] = {20, 60, 20, 40, 20, 10, 10} -- canas more mag for warp
P.GROWTH_WEIGHTS[7][NINIAN_NILS] = {30, 00, 00, 20, 20, 10, 10} -- ideally won't take more than 1 hit anyway
P.BOOSTERS[7][KENT]  = {0, 0, 0, 2, 0, 2, 2, 0} -- talisman, wings, icon
P.BOOSTERS[7][HEATH] = {0, 0, 0, 0, 2, 0, 0, 0} -- shield
P.BOOSTERS[7][ATHOS] = {7, 0, 0, 0, 0, 0, 0, 0} -- robe

P.PROMOTED_AT[7] = {
19,  0,  0, 15,  0, -- Eliwood Lowen Marcus Rebecca Dorcas
 0, 20,  0,  0,  0, -- Bartre Hector Oswin Serra Matthew
17,  0,  0,  0,  0, -- Guy Merlinus Erk Priscilla Lyn
 0, 11,  0,  0,  0, -- Wil Kent Sain Florina Raven
 0, 16,  0,  0,  0, -- Lucius Canas Dart Fiora Legault
 0,  0, 11,  0,  0, -- Ninian/Nils Isadora Heath Rath Hawkeye
 0,  0,  0,  0,  0, -- Geitz Wallace Farina Pent Louise
 0,  0,  0,  0,  0, -- Karel Harken Nino Jaffar Vaida
 0,  0,  0 			-- Karla Renault Athos
}

indexer = 0
local EIRIKA = nextInd()
local SETH = nextInd()
local FRANZ = nextInd()
local GILLIAM = nextInd()
local MOULDER = nextInd()
local VANESSA = nextInd()
local ROSS = nextInd()
local GARCIA = nextInd()
local NEIMI = nextInd()
local COLM = nextInd()
local ARTUR = nextInd()
local LUTE = nextInd()
local NATASHA = nextInd()
local JOSHUA = nextInd()
local EPHRAIM = nextInd()
local FORDE = nextInd()
local KYLE = nextInd()
local TANA = nextInd()
local AMELIA = nextInd()
local INNES = nextInd()
local GERIK = nextInd()
local TETHYS = nextInd()
local MARISA = nextInd()
local LARACHEL = nextInd()
local DOZLA = nextInd()
local SALEH = nextInd()
local EWAN = nextInd()
local CORMAG = nextInd()
local RENNAC = nextInd()
local DUESSEL = nextInd()
local KNOLL = nextInd()
local MYRRH = nextInd()
local SYRENE = nextInd()
local CAELLACH = nextInd()
local ORSON = nextInd()
local RIEV = nextInd()
local ISMAIRE = nextInd()
local SELENA = nextInd()
local GLEN = nextInd()
local HAYDEN = nextInd()
local VALTER = nextInd()
local FADO = nextInd()
local LYON = nextInd()

P.NUM_OF_UNITS[8] = indexer -- including the 10 unlockable postgame units
P.NAMES[8] = {
"Eirika", "Seth", "Franz", "Gilliam", "Moulder",
"Vanessa", "Ross", "Garcia", "Neimi", "Colm",
"Artur", "Lute", "Natasha", "Joshua", "Ephraim",
"Forde", "Kyle", "Tana", "Amelia", "Innes",
"Gerik", "Tethys", "Marisa", "L\'Arachel", "Dozla",
"Saleh", "Ewan", "Cormag", "Rennac", "Duessel",
"Knoll", "Myrrh", "Syrene", "Caellach", "Orson",
"Riev", "Ismaire", "Selena", "Glen", "Hayden",
"Valter", "Fado", "Lyon"}
P.GROWTHS[8] = {
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
P.BASE_STATS[8] = {
{16, 04, 08, 09, 03, 01, 05, 01}, --Eirika
{30, 14, 13, 12, 11, 08, 13, 01}, --Seth
{20, 07, 05, 07, 06, 01, 02, 01}, --Franz
{25, 09, 06, 03, 09, 03, 03, 04}, --Gilliam
{20, 04, 06, 09, 02, 05, 01, 03}, --Moulder
{17, 05, 07, 11, 06, 05, 04, 01}, --Vanessa
{15, 05, 02, 03, 03, 00, 08, 01}, --Ross
{28, 08, 07, 07, 05, 01, 03, 04}, --Garcia
{17, 04, 05, 06, 03, 02, 04, 01}, --Neimi
{18, 04, 04, 10, 03, 01, 08, 02}, --Colm
{19, 06, 06, 08, 02, 06, 02, 02}, --Artur
{17, 06, 06, 07, 03, 05, 08, 01}, --Lute
{18, 02, 04, 08, 02, 06, 08, 01}, --Natasha
{24, 08, 13, 14, 05, 02, 07, 05}, --Joshua
{23, 08, 09, 11, 07, 02, 08, 04}, --Ephraim
{24, 07, 08, 08, 08, 02, 07, 06}, --Forde
{25, 09, 06, 07, 09, 01, 06, 05}, --Kyle
{20, 07, 09, 13, 06, 07, 08, 04}, --Tana
{16, 04, 03, 04, 02, 03, 06, 01}, --Amelia
{31, 14, 13, 15, 10, 09, 14, 01}, --Innes
{32, 14, 13, 13, 10, 04, 08, 10}, --Gerik
{18, 01, 02, 12, 05, 04, 10, 01}, --Tethys
{23, 07, 12, 13, 04, 03, 09, 05}, --Marisa
{18, 06, 06, 10, 05, 08, 12, 03}, --L’Arachel
{43, 16, 11, 09, 11, 06, 04, 01}, --Dozla
{30, 16, 18, 14, 08, 13, 11, 01}, --Saleh
{15, 03, 02, 05, 00, 03, 05, 01}, --Ewan
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
P.CLASSES[8] = {
classes.F.LORD,				--Eirika
classes.M.PALADIN,			--Seth
classes.M.CAVALIER,			--Franz
classes.M.ARMOR_KNIGHT,		--Gilliam
classes.M.CLERIC,			--Moulder
classes.F.PEGASUS_KNIGHT,	--Vanessa
classes.M.JOURNEYMAN,		--Ross
classes.M.FIGHTER,			--Garcia
classes.F.ARCHER,			--Neimi
classes.M.THIEF,			--Colm
classes.M.MONK,				--Artur
classes.F.MAGE,				--Lute
classes.F.CLERIC,			--Natasha
classes.M.MYRMIDON,			--Joshua
classes.M.LORD,				--Ephraim
classes.M.CAVALIER,			--Forde
classes.M.CAVALIER,			--Kyle
classes.F.PEGASUS_KNIGHT,	--Tana
classes.F.RECRUIT,			--Amelia
classes.M.SNIPER,			--Innes
classes.M.MERCENARY,		--Gerik
classes.F.DANCER,			--Tethys
classes.F.MYRMIDON,			--Marisa
classes.F.TROUBADOUR,		--L’Arachel
classes.M.BERSERKER,		--Dozla
classes.M.SAGE,				--Saleh
classes.M.PUPIL,			--Ewan
classes.M.WYVERN_RIDER,		--Cormag
classes.M.ROGUE,			--Rennac
classes.M.GREAT_KNIGHT,		--Duessel 
classes.M.SHAMAN,			--Knoll
classes.F.MANAKETE,			--Myrrh
classes.F.FALCO_KNIGHT,		--Syrene
classes.M.HERO,				--Caellach
classes.M.PALADIN,			--Orson
classes.M.BISHOP,			--Riev
classes.F.SWORDMASTER,		--Ismaire
classes.F.MAGE_KNIGHT,		--Selena
classes.M.WYVERN_LORD,		--Glen
classes.M.RANGER,			--Hayden
classes.M.WYVERN_KNIGHT,	--Valter
classes.M.GENERAL,			--Fado
classes.M.NECROMANCER		--Lyon
}
P.PROMOTIONS[8] = {
classes.F.GREAT_LORD8,		--Eirika
classes.M.PALADIN,			--Seth
classes.M.PALADIN,			--Franz
classes.M.GREAT_KNIGHT,		--Gilliam
classes.M.BISHOP,			--Moulder SAGE
classes.F.WYVERN_KNIGHT,	--Vanessa
classes.M.BERSERKER,		--Ross
classes.M.WARRIOR,			--Garcia HERO
classes.F.RANGER, 			--Neimi
classes.M.ASSASSIN,			--Colm
classes.M.BISHOP, 			--Artur SAGE
classes.F.MAGE_KNIGHT, 		--Lute
classes.F.VALKYRIE,			--Natasha
classes.M.SWORDMASTER,		--Joshua
classes.M.GREAT_LORD8,		--Ephraim
classes.M.PALADIN,			--Forde
classes.M.PALADIN,			--Kyle
classes.F.WYVERN_KNIGHT, 	--Tana
classes.F.PALADIN,			--Amelia
classes.M.SNIPER,			--Innes
classes.M.RANGER,			--Gerik HERO
classes.F.DANCER,			--Tethys
classes.F.SWORDMASTER,		--Marisa
classes.F.MAGE_KNIGHT,		--L’Arachel
classes.M.BERSERKER,		--Dozla
classes.M.SAGE,				--Saleh
classes.M.MAGE_KNIGHT,		--Ewan
classes.M.WYVERN_KNIGHT,	--Cormag
classes.M.ROGUE,			--Rennac
classes.M.GREAT_KNIGHT,		--Duessel 
classes.M.SUMMONER,			--Knoll
classes.F.MANAKETE,			--Myrrh
classes.F.FALCO_KNIGHT,		--Syrene
classes.M.HERO,				--Caellach
classes.M.PALADIN,			--Orson
classes.M.BISHOP,			--Riev
classes.F.SWORDMASTER,		--Ismaire
classes.F.MAGE_KNIGHT,		--Selena
classes.M.WYVERN_LORD,		--Glen
classes.M.RANGER,			--Hayden
classes.M.WYVERN_KNIGHT,	--Valter
classes.M.GENERAL,			--Fado
classes.M.NECROMANCER		--Lyon
}

P.DEPLOYED[8] = {}
P.BOOSTERS[8] = {}
P.GROWTH_WEIGHTS[8] = {}
for unit_i = 1, P.NUM_OF_UNITS[8] do
	P.GROWTH_WEIGHTS[8][unit_i] = {20, 40, 20, 50, 30, 10, 10}
	P.BOOSTERS[8][unit_i] = {0, 0, 0, 0, 0, 0, 0, 0}
end

P.DEPLOYED[8][EIRIKA] = true
P.GROWTH_WEIGHTS[8][TETHYS] = {30, 00, 00, 20, 20, 10, 10} -- ideally won't take more than 1 hit anyway

P.PROMOTED_AT[8] = {
 0,  0,  0,  0,  0, -- Eirika Seth Franz Gilliam Moulder
 0,  0,  0,  0,  0, -- Vanessa Ross Garcia Neimi Colm
 0,  0,  0,  0,  0, -- Artur Lute Natasha Joshua Ephraim
 0,  0,  0,  0,  0, -- Forde Kyle Tana Amelia Innes
 0,  0,  0,  0,  0, -- Gerik Tethys Marisa L'Arachel Dozla
 0,  0,  0,  0,  0, -- Saleh Ewan Cormag Rennac Duessel
 0,  0,  0,  0,  0, -- Knoll Myrrh Syrene Caellach Orson
 0,  0,  0,  0,  0, -- Riev Ismaire Selena Glen Hayden
 0,  0,  0			-- Valter Fado Lyon
}


P.sel_Unit_i = 1

function P.numOf() 
	return P.NUM_OF_UNITS[version]
end

function P.names(unit_i) -- default value P.sel_Unit_i
	unit_i = unit_i or P.sel_Unit_i
	return P.NAMES[version][unit_i]
end

function P.deployed(unit_i) 
	unit_i = unit_i or P.sel_Unit_i
	return P.DEPLOYED[version][unit_i]
end

local Afas = 0
function P.setAfas(unit_i)
	unit_i = unit_i or P.sel_Unit_i
	
	if Afas == P.sel_Unit_i then
		Afas = 0
		print("Afa's removed from " .. P.names(unit_i))
	else
		Afas = P.sel_Unit_i
		print("Afa's applied to " .. P.names(unit_i))
	end
end

function P.growths(unit_i) 
	unit_i = unit_i or P.sel_Unit_i
	
	if unit_i ~= Afas then
		return P.GROWTHS[version][unit_i]
	end
	
	local afasGrowths = {}
	for stat_i = 1, 7 do
		afasGrowths[stat_i] = 
			P.GROWTHS[version][unit_i][stat_i] + 5
	end
	return afasGrowths
end

function P.growthWeights(unit_i)
	unit_i = unit_i or P.sel_Unit_i
	return P.GROWTH_WEIGHTS[version][unit_i]
end

function P.hasPromoted(unit_i)
	return P.PROMOTED_AT[version][unit_i] > 0
end

function P.canPromote(unit_i)
	return P.class(unit_i) ~= P.promotion(unit_i)
end

function P.levelsPrePromotion(unit_i)
	return P.PROMOTED_AT[version][unit_i] - P.BASE_STATS[version][unit_i][P.LEVEL_I]
end

function P.class(unit_i)
	unit_i = unit_i or P.sel_Unit_i
		
	if P.hasPromoted(unit_i) then
		return P.promotion(unit_i)
	end
	return P.CLASSES[version][unit_i]
end

function P.promotion(unit_i)
	unit_i = unit_i or P.sel_Unit_i
	
	return P.PROMOTIONS[version][unit_i]
end

function P.bases(unit_i)
	unit_i = unit_i or P.sel_Unit_i
	
	local ret = {}
	for stat_i = 1, 8 do
		ret[stat_i] = P.BASE_STATS[version][unit_i][stat_i] + P.BOOSTERS[version][unit_i][stat_i]
	end
	
	if not P.hasPromoted(unit_i) then
		return ret
	end
	
	for stat_i = 1, 7 do
		ret[stat_i] = ret[stat_i] + classes.PROMO_GAINS[P.class(unit_i)][stat_i]
	end
	ret[P.LEVEL_I] = 1 - P.levelsPrePromotion(unit_i)
	return ret
end

function P.nextDeployed()
	local canditate_i = P.sel_Unit_i
	canditate_i = rotInc(canditate_i, P.numOf())
	while (canditate_i ~= P.sel_Unit_i and not P.deployed(canditate_i)) do
		canditate_i = rotInc(canditate_i, P.numOf())
	end
	return canditate_i
end

local savedStats = {0, 0, 0, 0, 0, 0, 0, 0, 0} -- last two are level, exp
function P.getSavedStats() -- needed for RNBE construction
	return savedStats
end

function P.willLevelStat(HP_RN_i, unit_i, charStats)
	unit_i = unit_i or P.sel_Unit_i
	charStats = charStats or savedStats
	
	ret = {}	
	
	if unit_i ~= Afas then
		for stat_i = 1, 7 do
			if charStats[stat_i] >= classes.CAPS[P.class(unit_i)][stat_i] then
				ret[stat_i] = -1 -- stat capped
			elseif rns.rng1:getRNasCent(HP_RN_i+stat_i-1) < P.growths(unit_i)[stat_i] then
				ret[stat_i] = 1 -- stat grows
			else
				ret[stat_i] = 0 -- stat doesn't grow
			end
		end
	else
		for stat_i = 1, 7 do
			if charStats[stat_i] >= classes.CAPS[P.class(unit_i)][stat_i] then
				ret[stat_i] = -1 -- stat capped
			elseif rns.rng1:getRNasCent(HP_RN_i+stat_i-1) < P.growths(unit_i)[stat_i] - 5 then
				ret[stat_i] = 1 -- stat grows without afa's
			elseif rns.rng1:getRNasCent(HP_RN_i+stat_i-1) < P.growths(unit_i)[stat_i] then
				ret[stat_i] = 2 -- stat grows because of afa's
			else
				ret[stat_i] = 0 -- stat doesn't grow
			end
		end
	end
	
	return ret
end

function P.levelUpProcs_string(HP_RN_i, unit_i, charStats)
	unit_i = unit_i or P.sel_Unit_i
	charStats = charStats or savedStats
	
	local seq = ""
	local statRaised = false
	local statCapped = false
	
	local procs = P.willLevelStat(HP_RN_i, unit_i, charStats)
	
	for stat_i = 1, 7 do
		
		if procs[stat_i] == 1 then
			seq = seq .. "+" -- grows this stat
			statRaised = true
		elseif procs[stat_i] == 2 then
			seq = seq .. "!" -- grows this stat because of Afa's
			statRaised = true
		elseif procs[stat_i] == -1 then
			seq = seq .. "_" -- can't grow stat
			statCapped = true
		else
			seq = seq .. "."
		end
	end
	if (not statRaised) and (not statCapped) then
		seq = seq .. " EMPTY, may proc more RNs!" 
		-- todo how does this work?
		-- continue rolling, one rn at a time, until a stat grows?
	end
	return seq
end

-- works for levels too
local function statsGained(stat_i, unit_i, stat)
	unit_i = unit_i or P.sel_Unit_i
	stat = stat or savedStats[stat_i]
	
	if stat_i == P.LEVEL_I and P.hasPromoted(unit_i) then
		return stat - 1 + P.levelsPrePromotion(unit_i)
	end
	
	return stat - P.bases(unit_i)[stat_i]
end

-- scored from 1 (procing every level will not exceed the cap) to 0 (at cap or lvl 20)
-- 3/4 means level 16, 3 stats away from cap (or level 12, 6 stats away etc)
-- once used in P.expValueFactor(unit_i, charStats)
local function procRatioNeededForCap(unit_i, charStats)
	unit_i = unit_i or P.sel_Unit_i
	charStats = charStats or savedStats
	
	local ret = {}
	
	local levelsTil20 = 20 - charStats[P.LEVEL_I]
	for stat_i = 1, 7 do
		if levelsTil20 <= 0 then
			ret[stat_i] = 0
		else
			local procsTilStatCap = classes.CAPS[P.class(unit_i)][stat_i] - charStats[stat_i]
			ret[stat_i] = math.min(1, procsTilStatCap/levelsTil20)
		end
	end

	return ret
end

local function growthRateNeededToCap(unit_i, charStats)
	unit_i = unit_i or P.sel_Unit_i
	charStats = charStats or savedStats
	
	local ret = {}
	
	local levelsTil20 = 20 - charStats[P.LEVEL_I]
	for stat_i = 1, 7 do
		if levelsTil20 <= 0 then
			ret[stat_i] = 0
		else
			local procsTilStatCap = classes.CAPS[P.class(unit_i)][stat_i] - charStats[stat_i]
			ret[stat_i] = procsTilStatCap/levelsTil20
		end
	end
	
	return ret
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

-- adjusts preset stat value weights downward when 
-- natural growth rates are likely to hit the cap
local function dynamicStatWeights(unit_i, charStats)
	unit_i = unit_i or P.sel_Unit_i
	
	if P.class(unit_i) == classes.F.DANCER or P.class(unit_i) == classes.M.BARD then
		return P.growthWeights(unit_i)
	end
	
	charStats = charStats or savedStats
	local ret = {}
	
	local levelsTil20 = 20 - charStats[P.LEVEL_I]
	for stat_i = 1, 7 do
		if levelsTil20 <= 0 then
			ret[stat_i] = 0
		else
			local procsTilStatCap = classes.CAPS[P.class(unit_i)][stat_i] - charStats[stat_i]
			
			-- multiply by 1 - P(reaching/exceeding cap even if not gaining stat this level)
			-- if no chance to reach cap if not leveling, full weight
			-- if 100% chance (ie at cap), no weight
			
			-- 1 - P(reaching/exceeding cap | not gaining stat this level) =
			-- 1 - (1 - P(less than cap | gained levelsTil20 - 1 levels)) =
			-- P(less than cap | gained levelsTil20 - 1 levels)
			
			local probCapUnreachableIfNotProcing = 
				cumulativeBinDistrib(procsTilStatCap-1, levelsTil20-1, P.growths(unit_i)[stat_i]/100)
			
			-- if more likely to hit promoted class cap than unpromoted, use that probability
			if P.canPromote(unit_i) then
				local procsTilStatCap_P = classes.CAPS[P.promotion(unit_i)][stat_i] 
					- charStats[stat_i] - classes.PROMO_GAINS[P.promotion(unit_i)][stat_i]
				
				-- may need levels to even reach promotion
				local levelsTil20_P = 19 + math.max(10 - charStats[P.LEVEL_I], 0)
				
				probCapUnreachableIfNotProcing_P = 
					cumulativeBinDistrib(procsTilStatCap_P-1, levelsTil20_P-1, P.growths(unit_i)[stat_i]/100)
					
				if probCapUnreachableIfNotProcing > probCapUnreachableIfNotProcing_P then
					probCapUnreachableIfNotProcing = probCapUnreachableIfNotProcing_P
				end
			end
			
			ret[stat_i] = P.growthWeights(unit_i)[stat_i]*probCapUnreachableIfNotProcing
		end
	end
	
	return ret
end

-- if growth rate needed to cap is less than growth rate, reduce proportionally
function P.expValueFactor(unit_i, charStats)
	unit_i = unit_i or P.sel_Unit_i
	charStats = charStats or savedStats
	
	local ret = 0
	local weightTotal = 0
	local dSW = dynamicStatWeights(unit_i, charStats)
	
	for stat_i = 1, 7 do
		weightTotal = weightTotal + P.growthWeights(unit_i)[stat_i]
		ret = ret + dSW[stat_i]
	end
	
	if weightTotal == 0 then return 0 end
	
	return ret/weightTotal
end

-- gets score for level up starting at rns index HP_RN_i
-- scored such that average level is 0, empty level is -100
-- in units of exp: empty level wipes out value of exp used to level up

function P.statProcScore(HP_RN_i, unit_i, charStats)
	unit_i = unit_i or P.sel_Unit_i
	charStats = charStats or savedStats
	
	local score = 0
	local avg = 0
	
	local procs = P.willLevelStat(HP_RN_i, unit_i, charStats)
	local dSW = dynamicStatWeights(unit_i, charStats)
	
	for stat_i = 1, 7 do
		if procs[stat_i] > 0 then
			score = score + 100 * dSW[stat_i]
		end
		avg = avg + P.growths(unit_i)[stat_i] * dSW[stat_i] -- growths are in cents
	end
	
	if avg == 0 then return 0 end
	
	score = score - avg
	
	return 100*score/avg
end

local function statAverageAt(stat_i, unit_i, level)
	unit_i = unit_i or P.sel_Unit_i
	level = level or savedStats[P.LEVEL_I]
	
	return P.bases(unit_i)[stat_i] 
			+ (statsGained(P.LEVEL_I, unit_i, level)
			* P.growths(unit_i)[stat_i] / 100)
end

function P.statDeviation(stat_i, unit_i, charStat, charLevel)
	unit_i = unit_i or P.sel_Unit_i
	charStat = charStat or savedStats[stat_i]
	charLevel = charLevel or savedStats[P.LEVEL_I]
	
	return charStat - statAverageAt(stat_i, unit_i, charLevel)
end

-- how many sigma's off from average
function P.statStdDev(stat_i, unit_i, charStat)
	unit_i = unit_i or P.sel_Unit_i
	charStat = charStat or savedStats[stat_i]
	
	local levelsGained = statsGained(P.LEVEL_I, unit_i)
	if levelsGained == 0 then return 0 end
	
	local stdDev = (levelsGained*P.growths(unit_i)[stat_i]*
		(100-P.growths(unit_i)[stat_i])/10000)^0.5

	return P.statDeviation(stat_i, unit_i, charStat)/stdDev
end

function P.statDevWeightedTotal(unit_i, charStats)
	unit_i = unit_i or P.sel_Unit_i
	charStats = charStats or savedStats
	
	local ret = 0
	for stat_i = 1, 7 do
		ret = ret + P.statDeviation(stat_i, unit_i, charStats[stat_i])
			*P.growthWeights(unit_i)[stat_i]
	end
	return ret
end

-- characters stats evaluated against X random characters at the same level
function P.percentile(unit_i, charStats)
	unit_i = unit_i or P.sel_Unit_i
	charStats = charStats or savedStats
	local numOfTrials = 1000

	local levelsGained = statsGained(P.LEVEL_I, unit_i)
	local charStatsScore = 0
	for stat_i = 1, 7 do
		charStatsScore = charStatsScore + 
			charStats[stat_i]*P.growthWeights(unit_i)[stat_i]
	end

	local worseTrials = 0
	for trial_i = 1, numOfTrials do
		local trialScore = 0
		for stat_i = 1, 7 do
			trialScore = trialScore + P.growthWeights(unit_i)[stat_i]
				*P.bases(unit_i)[stat_i]
			for level_i = 1, levelsGained do
				if math.random(0, 99) < P.growths(unit_i)[stat_i] then
					trialScore = trialScore + P.growthWeights(unit_i)[stat_i]
				end
			end
		end
		if trialScore <= charStatsScore then
			worseTrials = worseTrials + 1
		end
	end
	return worseTrials/numOfTrials
end

function P.effectiveGrowthRate(stat_i, unit_i, charStat)
	unit_i = unit_i or P.sel_Unit_i
	charStat = charStat or savedStats[stat_i]
	
	local levelsGained = statsGained(P.LEVEL_I, unit_i)
	if levelsGained == 0 then return 0 end
	return 100*statsGained(stat_i, unit_i, charStat)/levelsGained
end

local statMaxHpAddr = {}
statMaxHpAddr[6] = 0x02039224
statMaxHpAddr[7] = 0x0203A402 -- A403, A462?
statMaxHpAddr[8] = 0x0203A4FE
local statScreenBase = {}
statScreenBase[6] = 0x02039226
statScreenBase[7] = 0x0203A404
statScreenBase[8] = 0x0203A500
local statLevelAddr = {}
statLevelAddr[6] = 0x0203921C -- ..80?
statLevelAddr[7] = 0x0203A3F8 -- ..406?
statLevelAddr[8] = 0x0203A55C -- ..4F4?
local statExpAddr = {} 
statExpAddr[6] = 0x0203921D -- ..81?
statExpAddr[7] = 0x0203A3F9 -- ..461?
statExpAddr[8] = 0x0203A55D -- ..4F5?

function P.saveStats()
	savedStats[1] = memory.readbyte(statMaxHpAddr[version])
	for stat_i = 2, 7 do
		savedStats[stat_i] = memory.readbyte(statScreenBase[version] + stat_i - 2)
	end
	savedStats[8] = memory.readbyte(statLevelAddr[version])
	savedStats[9] = memory.readbyte(statExpAddr[version])
end

function P.statData_strings() -- index from 0
	local ret = {}
	
	local showPromo = P.canPromote() and feGUI.pulse(480)
	
	local indexer = -1
	local function nextInd()
		indexer = indexer+1
		return indexer
	end
	local STAT_HEAD = nextInd()
	
	local STATS = nextInd()
	
	local CAPS = nextInd()
	local WEIGHTS = nextInd()
	
	local GROWTHS = nextInd()
	local EF_GROW = nextInd()
	local STND_DEV = nextInd()
	
	ret[STAT_HEAD]	= string.format("%-10.10sLv Xp Hp St Sk Sp Df Rs Lk", P.names())
	
	ret[STATS]		= "Stats    " .. string.format(" %02d %02d", savedStats[P.LEVEL_I], savedStats[9])
	if savedStats[9] == 255 then
		ret[STATS]	= "Stats    " .. string.format(" %02d --", savedStats[P.LEVEL_I])
	end
	ret[CAPS]		= "Caps           " 	
	if showPromo then
		ret[CAPS]		= "Caps      PROMO" 
	end
	
	ret[WEIGHTS]	= "Weights  " .. string.format(" x%4.2f", P.expValueFactor(unit_i, charStats))
	if P.sel_Unit_i ~= Afas then
		ret[GROWTHS]= "Growths        "
	else
		ret[GROWTHS]= "Growths +Afa's "
	end
	ret[EF_GROW]	= "Actual Growths "
	ret[STND_DEV]	= "Standard Dev   "
	
	local dSW = dynamicStatWeights(unit_i, charStats)
	for stat_i = 1, 7 do
		ret[GROWTHS] = ret[GROWTHS] .. 
				string.format(" %02d", P.growths()[stat_i])
		
		if showPromo then
			ret[STATS] = ret[STATS] .. string.format(" %02d", savedStats[stat_i] 
					+ classes.PROMO_GAINS[P.promotion(unit_i)][stat_i])
		else
			ret[STATS] = ret[STATS] .. string.format(" %02d", savedStats[stat_i])
		end
		
		if showPromo then
			ret[CAPS] = ret[CAPS] .. string.format(" %02d", classes.CAPS[P.promotion(unit_i)][stat_i])
		else
			ret[CAPS] = ret[CAPS] .. string.format(" %02d", classes.CAPS[P.class()][stat_i])
		end
		
		ret[WEIGHTS] = ret[WEIGHTS] .. 
				string.format(" %02d", dSW[stat_i])
		
		if P.effectiveGrowthRate(stat_i) < 100 then
			ret[EF_GROW] = ret[EF_GROW] .. 
					string.format(" %02d", P.effectiveGrowthRate(stat_i))
		else
			ret[EF_GROW] = ret[EF_GROW] .. " A0"
		end
		
		local stdDv = P.statStdDev(stat_i)
		ret[STND_DEV] = ret[STND_DEV] .. string.format("%+03d", 10*stdDv)
	end
	
	return ret
end

-- variable rather than function because don't want to recalc each frame
P.levelUp_strings = {}
P.levelUp_stringsSize = 0
-- index from 0
function P.setLevelUpStrings()
	P.levelUp_strings = {}
	
	P.levelUp_strings[0] = string.format(" =Level Ups: %s=", unitData.names())
	P.levelUp_stringsSize = 1
	
	-- detect upcoming good levels		
	local recordScore = 0 -- average
	
	for relLevelUp_pos = 0, 90 do
		local levelUp_pos = rns.rng1.pos + relLevelUp_pos
		
		levelUpScore = unitData.statProcScore(levelUp_pos)
		
		if levelUpScore > recordScore then	
			-- find valid prior combat simulations if they exist
			local maxCombat = 24 -- 2 brave weapons, all crits
			if relLevelUp_pos < maxCombat then
				maxCombat = relLevelUp_pos
			end
			
			local sequenceFound = false
			local seqString = string.format("%0.2f %s", 
				levelUpScore, unitData.levelUpProcs_string(levelUp_pos))
			
			for combatLength = maxCombat, 0, -1 do
				if combat.currBattleParams:hitSeq(levelUp_pos-combatLength).RNsConsumed
						== combatLength then -- valid sequence
						
					sequenceFound = true
					seqString = seqString .. 
						string.format(" @%2d %s", relLevelUp_pos-combatLength, 
						combat.hitSeq_string(
							combat.currBattleParams:hitSeq(levelUp_pos-combatLength)))
				end
			end
			
			if sequenceFound then
				P.levelUp_strings[P.levelUp_stringsSize] = seqString
				recordScore = levelUpScore
				P.levelUp_stringsSize = P.levelUp_stringsSize + 1
			end
		end
		
		recordScore = recordScore + 0.01 -- require at least 1 point improvement per rn
	end		
end

P.setLevelUpStrings()

return unitData
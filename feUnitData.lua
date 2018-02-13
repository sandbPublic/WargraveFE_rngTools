require("feRandomNumbers")
require("feClass")
require("feCombat")
require("feVersion")

local P = {}
unitData = P

-- luck is in the wrong place relative to what is shown on screen:
P.STAT_NAMES = {"HP", "Str", "Skl", "Spd", "Def", "Res", "Lck", "Lvl", "Exp"}

P.i_LUCK = 7
P.i_LEVEL = 8
P.i_EXP = 9

P.NUM_OF_UNITS = {}
P.NAMES = {}
P.DEPLOYED = {}
P.GROWTHS = {}
P.GROWTH_WEIGHTS = {}
P.BASE_STATS = {} -- store base stats, names, deployed, and classes in one table?
P.BASE_STATS_HM = {} -- hard mode
P.CLASSES = {}

P.NUM_OF_UNITS[6] = 54
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
P.DEPLOYED[6] = {
true, false, true, false, true, 
false, false, true, true, false,
true, true, false, true, false, 
false, true, false, false, false,

false, true, true, false, false, 
true, false, true, false, false,
true, false, true, false, false, 
false, false, false, true, false,

false, false, false, false, false, 
false, true, false, false, false,
false, false, false, true}
P.GROWTHS[6] = {
{80, 40, 50, 40, 25, 30, 60}, -- Roy
{60, 25, 20, 25, 15, 20, 20},
{85, 45, 40, 45, 25, 10, 40},
{80, 40, 45, 50, 20, 15, 35},
{80, 40, 50, 40, 20, 10, 40}, -- Wolt
{90, 30, 30, 40, 35, 10, 50},
{00, 00, 50, 50, 20, 05, 00}, -- Merlinus
{45, 50, 30, 20, 05, 60, 70},
{90, 40, 40, 30, 20, 15, 35},
{75, 50, 45, 20, 30, 05, 45}, -- Wade 
{80, 30, 30, 35, 40, 15, 30},
{45, 30, 55, 60, 10, 25, 60},
{85, 50, 50, 80, 25, 15, 60},
{50, 40, 50, 50, 15, 30, 35},
{40, 30, 40, 50, 10, 40, 65}, -- Clarine
{80, 30, 60, 50, 20, 20, 30},
{60, 40, 45, 45, 15, 50, 15},
{85, 50, 45, 45, 15, 15, 35}, -- Dorothy
{55, 30, 55, 65, 10, 15, 50},
{75, 25, 20, 20, 30, 15, 15},
{85, 40, 30, 35, 30, 05, 50},
{75, 30, 45, 30, 30, 10, 40},
{90, 35, 40, 50, 20, 20, 15},
{45, 75, 20, 35, 10, 35, 50},
{85, 40, 40, 40, 30, 10, 45},
{00, 60, 25, 20, 40, 02, 20},
{85, 40, 30, 45, 20, 15, 55},
{75, 25, 50, 55, 15, 20, 50},
{75, 45, 50, 50, 10, 15, 25},
{90, 60, 15, 50, 25, 05, 35},
{85, 50, 30, 40, 20, 10, 40},
{60, 35, 40, 45, 15, 25, 50},
{60, 40, 45, 55, 15, 20, 40},
{70, 10, 05, 70, 20, 30, 80},
{75, 30, 25, 30, 15, 15, 20},
{80, 05, 05, 65, 25, 55, 65},
{70, 40, 20, 30, 20, 05, 20},
{55, 45, 55, 40, 15, 35, 15},
{80, 40, 45, 85, 15, 20, 50},
{75, 50, 50, 45, 20, 05, 25},
{75, 30, 25, 35, 20, 10, 20},
{60, 35, 45, 25, 20, 25, 25},
{60, 55, 40, 30, 20, 55, 20},
{70, 35, 25, 35, 10, 05, 20},
{70, 45, 25, 25, 15, 05, 15},
{30, 90, 85, 65, 30, 50, 50}, -- Fa
{75, 30, 30, 45, 20, 15, 25},
{80, 60, 50, 35, 25, 05, 20},
{60, 30, 30, 30, 30, 05, 20},
{25, 15, 15, 15, 15, 20, 05}, -- Niime
{55, 20, 20, 15, 10, 10, 20},
{50, 20, 35, 30, 10, 10, 45},
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
P.GROWTH_WEIGHTS[6] = {}
for unit_i = 1, P.NUM_OF_UNITS[6] do
	P.GROWTH_WEIGHTS[6][unit_i] = {1.0, 2.0, 1.0, 2.0, 2.0, 1.0, 1.0}
end
P.CLASSES[6] = {
classes.M.MASTER_LORD, 		-- Roy LORD
classes.M.PALADIN, 			-- Marcus
classes.M.PALADIN, 			-- Allen CAVALIER
classes.M.PALADIN, 			-- Lance CAVALIER
classes.M.SNIPER, 			-- Wolt ARCHER
classes.M.GENERAL, 			-- Bors ARMOR_KNIGHT
classes.M.TRANSPORTER, 		-- Merlinus
classes.F.BISHOP, 			-- Ellen CLERIC
classes.M.HERO, 			-- Dieck MERCENARY
classes.M.WARRIOR, 			-- Wade FIGHTER
classes.M.WARRIOR, 			-- Lott FIGHTER
classes.F.PEGASUS_KNIGHT, 	-- Thany PEGASUS_KNIGHT
classes.M.THIEF, 			-- Chad
classes.M.SAGE, 			-- Lugh MAGE
classes.F.VALKYRIE, 		-- Clarine TROUBADOUR
classes.M.SWORDMASTER, 		-- Rutger MYRMIDON
classes.M.BISHOP, 			-- Saul CLERIC
classes.F.SNIPER, 			-- Dorothy ARCHER
classes.F.RANGER, 			-- Sue NOMAD
classes.M.PALADIN, 			-- Zealot
classes.M.PALADIN, 			-- Treck CAVALIER
classes.M.PALADIN, 			-- Noah CAVALIER
classes.M.THIEF, 			-- Astohl
classes.F.SAGE, 			-- Lilina MAGE
classes.F.GENERAL, 			-- Wendy ARMOR_KNIGHT
classes.M.GENERAL, 			-- Barth ARMOR_KNIGHT
classes.M.HERO, 			-- Oujay MERCENARY
classes.F.SWORDMASTER, 		-- Fir MYRMIDON
classes.M.RANGER, 			-- Shin NOMAD
classes.M.BERSERKER, 		-- Gonzales BRIGAND
classes.M.PIRATE, 			-- Geese PIRATE
classes.M.SNIPER, 			-- Klein							
classes.F.FALCO_KNIGHT, 	-- Tate PEGASUS_KNIGHT
classes.F.DANCER, 			-- Lalum
classes.F.HERO, 			-- Echidna
classes.M.BARD, 			-- Elphin
classes.M.WARRIOR, 			-- Bartre
classes.M.DRUID, 			-- Ray SHAMAN
classes.F.THIEF, 			-- Cath								
classes.F.WYVERN_LORD, 		-- Miredy WYVERN_RIDER
classes.M.PALADIN, 			-- Percival								
classes.F.VALKYRIE, 		-- Cecilia
classes.F.DRUID, 			-- Sofiya SHAMAN
classes.F.SNIPER, 			-- Igrene
classes.M.BERSERKER, 		-- Garret								
classes.F.MANAKETE, 		-- Fa
classes.M.MAGE, 			-- Hugh MAGE
classes.M.WYVERN_LORD, 		-- Zeis WYVERN_RIDER
classes.M.GENERAL, 			-- Douglas
classes.F.DRUID, 			-- Niime
classes.M.RANGER, 			-- Dayan
classes.F.FALCO_KNIGHT, 	-- Juno
classes.M.BISHOP, 			-- Yodel
classes.M.SWORDMASTER 		-- Karel
}

-- ninian/nils treated as one unit
P.NUM_OF_UNITS[7] = 43
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
P.DEPLOYED[7] = {
false, false, true, false, false, -- Marcus
true, true, false, false, true, -- Bartre, Hector, Matthew
false, false, false, false, false, 
true, false, true, false, false, -- Wil, Sain
false, false, true, false, false, -- Dart
false, false, false, false, false,
false, false, false, false, false, 
false, false, false, false, false,
false, false, false
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
--{60, 40, 50, 55, 15, 35, 50}, -- Florina
{65, 45, 55, 60, 20, 40, 55}, -- Florina --AFA'S
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
--{19, 07, 04, 05, 08, 02, 05, -19}, -- Hector GREAT_LORD7 PROMO @ 20 ICON TALIS
{28, 13, 09, 05, 13, 03, 03, 09}, -- Oswin
{17, 02, 05, 08, 02, 05, 06, 01}, -- Serra
{18, 04, 04, 11, 03, 00, 02, 02}, -- Matthew
--{21, 06, 11, 11, 05, 00, 05, 03}, -- Guy
  {33, 08, 11, 11, 07, 03, 05, -11}, -- Guy SWORDMASTER PROMO @ 15 ROBE, TALIS
{18, 00, 04, 05, 05, 02, 12, 05}, -- Merlinus
{17, 05, 06, 07, 02, 04, 03, 01}, -- Erk
{16, 06, 06, 08, 03, 06, 07, 03}, -- Priscilla
{18, 05, 10, 11, 02, 00, 05, 04}, -- Lyn
{21, 06, 05, 06, 05, 01, 07, 04}, -- Wil
--{23, 08, 07, 08, 06, 01, 04, 05}, -- Kent
  {25, 09, 08, 09, 08, 02, 04, -6}, -- Kent GAINED 7 LEVELS, PALADIN PROMO
--{22, 09, 05, 07, 07, 00, 05, 04}, -- Sain 
  {24, 10, 06, 10, 09, 01, 05, -10}, -- Sain PALADIN PROMO @ 15 SPEEDWINGS
--{18, 06, 08, 09, 04, 05, 08, 03}, -- Florina
  {30, 08, 08, 09, 08, 07, 08, -11}, -- Florina FALCO_KNIGHT PROMO @ 15 ROBE, SHIELD
--{25, 08, 11, 13, 05, 01, 02, 05}, -- Raven
  {29, 08, 13, 15, 07, 03, 04, -4}, -- Raven GAINED 5 LVLS, HERO PROMO, ICON
{18, 07, 06, 10, 01, 06, 02, 03}, -- Lucius
{21, 10, 09, 08, 05, 08, 07, 08}, -- Canas
{34, 12, 08, 08, 06, 01, 03, 08}, -- Dart
{21, 08, 11, 13, 06, 07, 06, 07}, -- Fiora
--{26, 08, 11, 15, 08, 03, 10, 12}, -- Legault
  {29, 09, 15, 15, 10, 05, 10, -7}, -- Legault GAINED 8 LVLS, ASSASSIN PROMO, 2BOOKS
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
-- hard mode bases?
P.GROWTH_WEIGHTS[7] = {}
for unit_i = 1, P.NUM_OF_UNITS[7] do
	P.GROWTH_WEIGHTS[7][unit_i] = {2, 4, 2, 5, 3, 1, 1}
	-- speed>str>def>skl=hp>res=luck
end

P.GROWTH_WEIGHTS[7][26] = {2, 0, 0, 2, 4, 1, 1}--Ninian/Nils

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
classes.M.LORD, -- Eliwood	
classes.M.CAVALIER, -- Lowen	
classes.M.PALADIN, -- Marcus	
classes.F.ARCHER, -- Rebecca	
classes.M.FIGHTER, -- Dorcas	
classes.M.WARRIOR, -- Bartre FIGHTER
classes.M.LORD, -- Hector
classes.M.ARMOR_KNIGHT, -- Oswin	
classes.F.CLERIC, -- Serra	
classes.M.THIEF, -- Matthew	
classes.M.MYRMIDON, -- Guy
classes.M.TRANSPORTER, -- Merlinus	
classes.M.MAGE, -- Erk
classes.F.TROUBADOUR, -- Priscilla	
classes.F.LORD, -- Lyn	
classes.M.ARCHER, -- Wil	
classes.M.CAVALIER, -- Kent
classes.M.PALADIN, -- Sain CAVALIER
classes.F.PEGASUS_KNIGHT, -- Florina
classes.M.MERCENARY, -- Raven
classes.M.MONK, -- Lucius
classes.M.SHAMAN, -- Canas	
classes.M.PIRATE, -- Dart	
classes.F.PEGASUS_KNIGHT, -- Fiora	
classes.M.THIEF, -- Legault
classes.F.DANCER, -- Ninian/Nils
classes.F.PALADIN, -- Isadora	
classes.M.WYVERN_RIDER, -- Heath	
classes.M.NOMAD, -- Rath
classes.M.BERSERKER, -- Hawkeye	
classes.M.WARRIOR, -- Geitz
classes.M.GENERAL, -- Wallace	
classes.F.PEGASUS_KNIGHT, -- Farina	
classes.M.SAGE, -- Pent	
classes.F.SNIPER, -- Louise	
classes.M.SWORDMASTER, -- Karel	
classes.M.HERO, -- Harken
classes.F.MAGE, -- Nino	
classes.M.ASSASSIN, -- Jaffar	
classes.F.WYVERN_LORD, -- Vaida
classes.F.SWORDMASTER, -- Karla	
classes.M.BISHOP, -- Renault	
classes.M.ARCHSAGE -- Athos
}

P.NUM_OF_UNITS[8] = 43 -- including the 10 unlockable postgame units
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
P.DEPLOYED[8] = {
true, false, false, false, true, 
false, true, true, false, true,
false, false, true, true, true, 
true, true, false, false, false,
false, true, false, false, false, 
false, false, false, false, false,
false, true, false, false, false, 
false, false, false, false, false,
false, false, false}
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
{85, 50, 55, 55, 45, 55, 30} --Lyon
}
P.GROWTH_WEIGHTS[8] = {}
for unit_i = 1, P.NUM_OF_UNITS[8] do
	P.GROWTH_WEIGHTS[8][unit_i] = {2, 4, 2, 4, 3, 1, 1}
end
--P.GROWTH_WEIGHTS[8][5]  = {1.0, 3.0, 0.2, 1.0, 2.0, 1.0, 0.5} -- Moulder
--P.GROWTH_WEIGHTS[8][13] = {1.0, 3.0, 0.2, 1.0, 2.0, 1.0, 0.5} -- Natasha
P.GROWTH_WEIGHTS[8][24] = {1.0, 3.0, 0.2, 1.0, 2.0, 1.0, 0.5} -- L'Arachel
P.GROWTH_WEIGHTS[8][22] = {2, 0, 0, 2, 4, 1, 1} -- Tethys
P.BASE_STATS[8] = {
{27, 06, 10, 10, 06, 06, 05, -17}, --Eirika +18 GREAT LORD, ROBE
{30, 14, 13, 12, 11, 08, 13, 01}, --Seth
{20, 07, 05, 07, 06, 01, 02, 01}, --Franz
{25, 09, 06, 03, 09, 03, 03, 04}, --Gilliam
{23, 10, 07, 09, 07, 07, 03, -6}, --Moulder +7 -> BISHOP ICON 2RING DSHIELD
{17, 05, 07, 11, 06, 05, 04, 01}, --Vanessa
{21, 08, 05, 05, 06, 02, 08, -20}, --Ross	+9 -> PIRATE +12 -> BERSERKER, BOOK
{31, 09, 09, 07, 08, 04, 03, -13}, --Garcia  +14 _> WARRIOR
{17, 04, 05, 06, 03, 02, 04, 01}, --Neimi
{21, 05, 06, 10, 05, 03, 08, -15}, --Colm 	+16 -> ASSASSIN, BOOK
{19, 06, 06, 08, 02, 06, 02, 02}, --Artur
{17, 06, 06, 07, 03, 05, 08, 01}, --Lute
{21, 04, 05, 08, 04, 09, 06, -8}, --Natasha +9 -> VALKYRIE
{29, 12, 13, 14, 07, 03, 07, -10}, --Joshua +11->SWORDMASTER ERING
{27, 10, 12, 13, 09, 07, 08, -10}, --Ephraim +11 GREAT LORD
{33, 08, 09, 11, 12, 03, 07, -6}, --Forde	ROBE WINGS SHIELD +7->PALADIN
{27, 10, 07, 08, 11, 02, 06, -9}, --Kyle +10->PALADIN
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
{25, 03, 01, 05, 12, 07, 03, 01}, --Myrrh +10 LEVELS, HP,DEF+10
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
classes.F.GREAT_LORD, --Eirika LORD
classes.M.PALADIN, --Seth
classes.M.CAVALIER, --Franz
classes.M.ARMOR_KNIGHT, --Gilliam 	
classes.M.BISHOP, --Moulder
classes.F.PEGASUS_KNIGHT, --Vanessa 	
classes.M.BERSERKER, --Ross 	
classes.M.WARRIOR, --Garcia FIGHTER
classes.F.ARCHER, --Neimi 	
classes.M.ASSASSIN, --Colm 	THIEF
classes.M.MONK, --Artur 	
classes.F.MAGE, --Lute 	
classes.F.VALKYRIE, --Natasha CLERIC
classes.M.SWORDMASTER, --Joshua MYRMIDON	
classes.M.GREAT_LORD8, --Ephraim LORD
classes.M.PALADIN, --Forde 	CAVALIER
classes.M.PALADIN, --Kyle 	
classes.F.PEGASUS_KNIGHT, --Tana 	
classes.F.RECRUIT, --Amelia 	
classes.M.SNIPER, --Innes 	
classes.M.MERCENARY, --Gerik 	
classes.F.DANCER, --Tethys 	
classes.F.MYRMIDON, --Marisa 	
classes.F.TROUBADOUR, --L’Arachel 	
classes.M.BERSERKER, --Dozla 	
classes.M.SAGE, --Saleh 	
classes.M.PUPIL, --Ewan 	
classes.M.WYVERN_RIDER, --Cormag 	
classes.M.ROGUE, --Rennac 	
classes.M.GREAT_KNIGHT, --Duessel 
classes.M.SHAMAN, --Knoll 	
classes.F.MANAKETE, --Myrrh
classes.F.FALCO_KNIGHT, --Syrene 	
classes.M.HERO, --Caellach 	
classes.M.PALADIN, --Orson 	
classes.M.BISHOP, --Riev 	
classes.F.SWORDMASTER, --Ismaire 	
classes.F.MAGE_KNIGHT, --Selena 	
classes.M.WYVERN_LORD, --Glen 	
classes.M.RANGER, --Hayden 	
classes.M.WYVERN_KNIGHT, --Valter 	
classes.M.GENERAL, --Fado 	
classes.M.NECROMANCER --Lyon
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
function P.growths(unit_i) 
	unit_i = unit_i or P.sel_Unit_i
	return P.GROWTHS[version][unit_i]
end
function P.growthWeights(unit_i)
	unit_i = unit_i or P.sel_Unit_i	
	return P.GROWTH_WEIGHTS[version][unit_i]
end
function P.bases(unit_i)
	unit_i = unit_i or P.sel_Unit_i
	return P.BASE_STATS[version][unit_i]
end
function P.class(unit_i)
	unit_i = unit_i or P.sel_Unit_i
	
	return P.CLASSES[version][unit_i]
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

function P.willLevelStat(stat_i, HP_RN_i, unit_i, charStats)
	unit_i = unit_i or P.sel_Unit_i
	charStats = charStats or savedStats
	
	if charStats[stat_i] >= classes.CAPS[P.class(unit_i)][stat_i] then
		return -1 -- stat capped
	end
	
	if (rns.getRNasCent(HP_RN_i+stat_i-1) < P.growths(unit_i)[stat_i]) then
		return 1 -- stat grows
	end
	
	return 0 -- stat doesn't grow
end

function P.levelUpProcs_string(HP_RN_i, unit_i, charStats)
	unit_i = unit_i or P.sel_Unit_i
	charStats = charStats or savedStats
	
	local seq = ""
	local statRaised = false
	local statCapped = false
	for stat_i = 1, 7 do
		local proc = P.willLevelStat(stat_i, HP_RN_i, unit_i, charStats)
		if proc == 1 then
			seq = seq .. "+" -- grows this stat
			statRaised = true
		elseif proc == -1 then
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

--works with levels too
local function statsGained(stat_i, unit_i, stat)
	unit_i = unit_i or P.sel_Unit_i
	stat = stat or savedStats[stat_i]
	
	return stat - P.bases(unit_i)[stat_i]
end

-- scored from 1 (procing every level will not exceed the cap) to 0 (at cap or lvl 20)
-- 3/4 means level 16, 3 stats away from cap (or level 12, 6 stats away etc)
local function procRatioNeededForCap(stat_i, unit_i, charStats)
	unit_i = unit_i or P.sel_Unit_i
	charStats = charStats or savedStats

	local levelsTil20 = 20 - charStats[P.i_LEVEL]
	if levelsTil20 < 0 then return levelsTil20 + 20 end
	if levelsTil20 == 0 then return 0 end
	
	procsTilStatCap = classes.CAPS[P.class(unit_i)][stat_i] - charStats[stat_i]
	
	return math.min(1, procsTilStatCap/levelsTil20)
end

-- as procRatioNeededForCap goes to 0, value of leveling
-- (and by extension, exp) declines
-- from 1 to 0
function P.expValueFactor(unit_i, charStats)
	unit_i = unit_i or P.sel_Unit_i
	charStats = charStats or savedStats
	
	local ret = 0
	local weightTotal = 0
	
	for stat_i = 1, 7 do
		weightTotal = weightTotal + P.growthWeights(unit_i)[stat_i]
		ret = ret + P.growthWeights(unit_i)[stat_i]*
			procRatioNeededForCap(stat_i, unit_i, charStats)
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
	for stat_i = 1, 7 do
		local weight = P.growthWeights(unit_i)[stat_i]
			* procRatioNeededForCap(stat_i, unit_i, charStats)
	
		if P.willLevelStat(stat_i, HP_RN_i, unit_i, charStats) == 1 then
			score = score + 100 * weight
		end
		avg = avg + P.growths(unit_i)[stat_i] * weight -- growths are in cents
	end
	
	if avg == 0 then return 0 end
	
	score = score - avg
	
	return 100*score/avg
end

local function statAverageAt(stat_i, unit_i, level)
	unit_i = unit_i or P.sel_Unit_i
	level = level or savedStats[P.i_LEVEL]
	
	return P.bases(unit_i)[stat_i] 
			+ (statsGained(P.i_LEVEL, unit_i, level)
			* P.growths(unit_i)[stat_i] / 100)
end

function P.statDeviation(stat_i, unit_i, charStat, charLevel)
	unit_i = unit_i or P.sel_Unit_i
	charStat = charStat or savedStats[stat_i]
	charLevel = charLevel or savedStats[P.i_LEVEL]
	
	return charStat - statAverageAt(stat_i, unit_i, charLevel)
end

-- how many sigma's off from average
function P.statStdDev(stat_i, unit_i, charStat)
	unit_i = unit_i or P.sel_Unit_i
	charStat = charStat or savedStats[stat_i]
	
	local levelsGained = statsGained(P.i_LEVEL, unit_i)
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

	local levelsGained = statsGained(P.i_LEVEL, unit_i)
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
	
	local levelsGained = statsGained(P.i_LEVEL, unit_i)
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
	
	local indexer = -1
	local function nextInd()
		indexer = indexer+1
		return indexer
	end
	local STAT_HEAD = nextInd()
	
	local STATS = nextInd()	
	local STD_DEV_A = nextInd() -- two lines to align
	local STD_DEV_B = nextInd()
	local CAPS = nextInd()
	local WEIGHTS = nextInd()
	
	local GROWTHS = nextInd()
	local EF_GROW = nextInd()
	local GROW_DEV = nextInd()
	
	ret[STAT_HEAD]	= string.format("%-10.10sHp St Sk Sp Df Rs Lk Lv Xp", P.names())
	ret[STATS]		= "Stats:   "
	ret[STD_DEV_A]	= "Std Dev: "
	ret[STD_DEV_B]	= "            "
	ret[CAPS]		= "Caps:    "
	ret[WEIGHTS]	= "Weights: "
	ret[GROWTHS]	= "Growths: "	
	ret[EF_GROW]	= "Ef Grow: "
	ret[GROW_DEV]	= "Grw Dev: "
		
	for stat_i = 1, 7 do
		ret[GROWTHS] = ret[GROWTHS] .. 
				string.format(" %02d", P.growths()[stat_i])
	
		ret[STATS] = ret[STATS] .. 
				string.format(" %02d", savedStats[stat_i])
		
		ret[CAPS] = ret[CAPS] .. 
				string.format(" %02d", classes.CAPS[P.class()][stat_i])
		
		
		ret[WEIGHTS] = ret[WEIGHTS] .. 
			string.format(" %02d", 10*P.growthWeights(unit_i)[stat_i]
			* procRatioNeededForCap(stat_i, unit_i, charStats))
		
		
		-- stat deviation, write across two lines to preserve alignment
		local stdDv = P.statStdDev(stat_i)
		local stdDvStr
		if stdDv < 0 then
			stdDvStr = string.format("%.1f  ", stdDv) -- align minus sign
		else
			stdDvStr = string.format(" %.1f  ", stdDv)
		end
		if (stat_i % 2 == 1) then
			ret[STD_DEV_A] = ret[STD_DEV_A] .. stdDvStr
		else
			ret[STD_DEV_B] = ret[STD_DEV_B] .. stdDvStr
		end
		
		if P.effectiveGrowthRate(stat_i) < 100 then
			ret[EF_GROW] = ret[EF_GROW] .. 
				string.format(" %02d", P.effectiveGrowthRate(stat_i))	
		else
			ret[EF_GROW] = ret[EF_GROW] .. " --"
		end
		
		local gDev = P.effectiveGrowthRate(stat_i) - P.growths()[stat_i]
		
		if gDev < 0 then 
			ret[GROW_DEV] = ret[GROW_DEV] .. string.format("%+03d", gDev)		
		else 
			ret[GROW_DEV] = ret[GROW_DEV] .. string.format("%+03d", gDev)
		end
	end
	
	ret[STATS] = ret[STATS] .. 
				string.format(" %02d", savedStats[P.i_LEVEL]).. 
				string.format(" %02d", savedStats[9])
	
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
		local levelUp_pos = rns.pos + relLevelUp_pos
		
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
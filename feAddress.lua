local P = {}
addr = P

GAME_VERSION = 7

local RAM_BASE = 0x02000000

-- 0,0 is upper left
-- FE6 + 0x11B0 = FE7, FE7 + 0xF8 = FE8
P.CURSOR_X = {0x2AA1C, 0x2BBCC, 0x2BCC4} -- also at +4
P.CURSOR_X = RAM_BASE + P.CURSOR_X[GAME_VERSION - 5]
P.CURSOR_Y = P.CURSOR_X + 2

-- todo money, {0x2AA50? 0x2BC00, 0x2BCF8?} -- 2 bytes, or more? 2 bytes maxes out at 65535, need extra half byte?
P.FOG = {0x2AA55, 0x2BC05, 0x2BCFD} -- +0x39 from CURSOR_X ?
P.FOG = RAM_BASE + P.FOG[GAME_VERSION - 5]
P.CHAPTER = P.FOG + 1 -- FE6x chapters count from 32
P.PHASE   = P.FOG + 2
P.TURN    = P.FOG + 3


-- FE6 + 0x11DC = FE7, FE7 + 0xFC = FE8
P.UNIT_NAME_CODE  = {0x39214, 0x3A3F0, 0x3A4EC} -- 2 bytes
P.UNIT_NAME_CODE  = RAM_BASE + P.UNIT_NAME_CODE[GAME_VERSION - 5]
P.UNIT_CLASS_CODE = P.UNIT_NAME_CODE +  4 -- 2 bytes
P.UNIT_LEVEL      = P.UNIT_NAME_CODE +  8 -- {0x3921C, 0x3A3F8, 0x3A4F4}
P.UNIT_EXP        = P.UNIT_NAME_CODE +  9 -- {0x3921D, 0x3A3F9, 0x3A4F5}
P.UNIT_SLOT_ID    = P.UNIT_NAME_CODE + 11 -- index of data source
P.UNIT_X = {0x39222, 0x3A400, 0x3A4FC} -- + 14,16,16
P.UNIT_X = RAM_BASE + P.UNIT_X[GAME_VERSION - 5]
P.UNIT_Y = P.UNIT_X + 1


P.UNIT_MAX_HP     = P.UNIT_NAME_CODE + 18 -- {0x39224, 0x3A402, 0x3A4FE}
-- next is current hp, then 6 other stats on stat screen
-- note "current" hp may be POST COMBAT hp on combat preview....
P.UNIT_ITEMS      = P.UNIT_MAX_HP + 12    -- {0x39230, 0x3A40E, 0x3A50A} 
-- weapons list in 10 bytes, (item,uses) x5
P.UNIT_ATK        = P.UNIT_MAX_HP + 0x48  -- {0x3926C, 0x3A44A, 0x3A546} includes weapon triangle
P.UNIT_DEF        = P.UNIT_ATK +  2       -- {0x3926E, 0x3A44C, 0x3A548} includes terrain bonus
P.UNIT_AS         = P.UNIT_ATK +  4       -- {0x39270, 0x3A44E, 0x3A54A} 
P.UNIT_HIT        = P.UNIT_ATK + 10       -- {0x39276, 0x3A454, 0x3A550} if can't attack, = 0xFF
-- redundant with stat screen values
-- P.UNIT_LUCK    = P.UNIT_ATK + 14       -- {0x3927A, 0x3A458, 0x3A554}
P.UNIT_CRIT       = P.UNIT_ATK + 16       -- {0x3927C, 0x3A45A, 0x3A556}
-- P.UNIT_LEVEL2  = {0x39280, 0x3A460, 0x3A55C}
-- P.UNIT_EXP2    = P.UNIT_LEVEL2 + 1
-- NOT redundant with stat screen, that address may show post combat hp
P.UNIT_CURR_HP    = {0x39282, 0x3A462, 0x3A55E}
P.UNIT_CURR_HP = RAM_BASE + P.UNIT_CURR_HP[GAME_VERSION - 5]

-- 8 consecutive bytes 26, 28, 28
P.UNIT_RANKS = {0x3923A, 0x3A418, 0x3A514}
P.UNIT_RANKS = RAM_BASE + P.UNIT_RANKS[GAME_VERSION - 5]
-- 10? consecutive bytes
P.UNIT_SUPPORTS = P.UNIT_RANKS + 10

-- same data structure exists for the defender in combat
P.DEFENDER_OFFSET = {0x7C, 0x80, 0x80}
P.DEFENDER_OFFSET = P.DEFENDER_OFFSET[GAME_VERSION - 5]


return P
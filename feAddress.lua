local P = {}
addr = P

GAME_VERSION = 7

local RAM_BASE = 0x02000000

-- 0,0 is upper left
-- FE6 + 0x11B0 = FE7, FE7 + 0xF8 = FE8
P.CURSOR_X = {0x2AA1C, 0x2BBCC, 0x2BCC4} -- also at +4
P.CURSOR_X = RAM_BASE + P.CURSOR_X[GAME_VERSION - 5]
P.CURSOR_Y = P.CURSOR_X + 2

P.FOG = {0x2AA55, 0x2BC05, 0x2BCFD} -- +0x39 from CURSOR_X ?
P.FOG = RAM_BASE + P.FOG[GAME_VERSION - 5]
P.PHASE = P.FOG + 2
P.TURN = P.PHASE + 1


-- FE6 + 0x11DC = FE7, FE7 + 0xFC = FE8
P.ATTACKER_NAME_CODE  = {0x39214, 0x3A3F0, 0x3A4EC} -- 2 bytes
P.ATTACKER_NAME_CODE  = RAM_BASE + P.ATTACKER_NAME_CODE[GAME_VERSION - 5]
P.ATTACKER_CLASS_CODE = P.ATTACKER_NAME_CODE +  4 -- 2 bytes
P.ATTACKER_LEVEL      = P.ATTACKER_NAME_CODE +  8 -- {0x3921C, 0x3A3F8, 0x3A4F4}
P.ATTACKER_EXP        = P.ATTACKER_NAME_CODE +  9
P.ATTACKER_SLOT_ID    = P.ATTACKER_NAME_CODE + 11 -- index of data source
P.ATTACKER_MAX_HP     = P.ATTACKER_NAME_CODE + 18 -- next is current hp, then 6 other stats on stat screen

-- 8 consecutive bytes
P.ATTACKER_RANKS = {0x3923A, 0x3A418, 0x3A514}
P.ATTACKER_RANKS = RAM_BASE + P.ATTACKER_RANKS[GAME_VERSION - 5]

local DEFENDER_OFFSET = {0x7C, 0x80, 0x80}
DEFENDER_OFFSET       = DEFENDER_OFFSET[GAME_VERSION - 5]

P.DEFENDER_NAME_CODE  = DEFENDER_OFFSET + P.ATTACKER_NAME_CODE
P.DEFENDER_CLASS_CODE = DEFENDER_OFFSET + P.ATTACKER_CLASS_CODE
P.DEFENDER_SLOT_ID    = DEFENDER_OFFSET + P.ATTACKER_SLOT_ID


return P
local P = {}
addr = P

GAME_VERSION = 7

local RAM_BASE = 0x02000000

-- 0,0 is upper left
-- FE6 + 0x11B0 = FE7, FE7 + 0xF8 = FE8
P.CURSOR_X = {0x2AA1C, 0x2BBCC, 0x2BCC4} -- also at +4
P.CURSOR_X = RAM_BASE + P.CURSOR_X[GAME_VERSION - 5]
P.CURSOR_Y = P.CURSOR_X + 2

P.MONEY    = {0x2AA50, 0x2BC00, 0x2BCF8} -- 4 bytes (except first bit, max out at 0x7FFFFFFF) todo FE6,8 untested
P.MONEY    = RAM_BASE + P.MONEY[GAME_VERSION - 5]

function P.getMoney()
	return memory.readword(P.MONEY+2)*0x10000 + memory.readword(P.MONEY)
end

function P.setMoney(money)
	local lowerWord = AND(money, 0x0000FFFF)
	local upperWord = AND(money, 0xFFFF0000)/0x10000

	memory.writeword(P.MONEY, lowerWord)
	memory.writeword(P.MONEY+2, upperWord)
end

P.FOG      = P.MONEY + 5 -- {0x2AA55, 0x2BC05, 0x2BCFD}
P.CHAPTER  = P.MONEY + 6 -- FE6x chapters count from 32
P.PHASE    = P.MONEY + 7
P.TURN     = P.MONEY + 8

-- FE6 + 0x11DC = FE7, FE7 + 0xFC = FE8

-- offsets are the same for slots, attacker, and defender
-- unit data occupies 0x48 (72) bytes per slot, followed by additional combat data for attacker/defender
P.SLOT_1_START   = {0x2AB78, 0x2BD50, 0x2BE4C}
P.SLOT_1_START   = RAM_BASE + P.SLOT_1_START[GAME_VERSION - 5]
P.ATTACKER_START = {0x39214, 0x3A3F0, 0x3A4EC}
P.ATTACKER_START = RAM_BASE + P.ATTACKER_START[GAME_VERSION - 5]
P.DEFENDER_START = {0x39290, 0x3A470, 0x3A56C}
P.DEFENDER_START = RAM_BASE + P.DEFENDER_START[GAME_VERSION - 5]

P.NAME_CODE_OFFSET  =  0 -- {0x39214, 0x3A3F0, 0x3A4EC} 2 bytes
P.CLASS_CODE_OFFSET =  4 -- {0x39216, 0x3A3F2, 0x3A4EE} 2 bytes
P.LEVEL_OFFSET      =  8 -- {0x3921C, 0x3A3F8, 0x3A4F4}
P.EXP_OFFSET        =  9 -- {0x3921D, 0x3A3F9, 0x3A4F5}
P.SLOT_ID_OFFSET    = 11 -- index of data source

-- bitmap: 
-- 00000001 0x01 pending stop
-- 00000010 0x02 stopped via combat
-- 01000010 0x42 stopped via wait
-- 00010000 0x10 rescuing
-- 00100001 0x21 is rescued before moving
-- 00100011 0x23 is rescued after being taken or moving
P.MOVED_OFFSET      = 12 -- {,0x3A3FC,} 
function P.unitIsStopped()
	return AND(memory.readbyte(P.MOVED_OFFSET), 2) > 0
end

P.X_OFFSET = {14, 16, 16}   -- {0x39222, 0x3A400, 0x3A4FC}
P.X_OFFSET = P.X_OFFSET[GAME_VERSION - 5]
P.Y_OFFSET = P.X_OFFSET + 1 -- {0x39223, 0x3A401, 0x3A4FD}


P.MAX_HP_OFFSET     = P.X_OFFSET + 2           -- {0x39224, 0x3A402, 0x3A4FE}
-- next is current hp, then 6 other stats on stat screen
-- note "current" hp may be POST COMBAT hp on combat preview....
-- inventory list in 10 bytes, (item,uses) x5
P.ITEMS_OFFSET      = P.MAX_HP_OFFSET + 12     -- {0x39230, 0x3A40E, 0x3A50A} 
-- 8 consecutive bytes 26, 28, 28
P.RANKS_OFFSET      = P.ITEMS_OFFSET + 10      -- {0x3923A, 0x3A418, 0x3A514}
-- status eg poison at + 8?
-- 10? consecutive bytes
P.SUPPORTS_OFFSET   = P.RANKS_OFFSET + 10      -- {0x39244, 0x3A422, 0x3A51E}




P.ATK_OFFSET        = P.SUPPORTS_OFFSET + 0x28 -- {0x3926C, 0x3A44A, 0x3A546} includes weapon triangle
P.DEF_OFFSET        = P.ATK_OFFSET +  2        -- {0x3926E, 0x3A44C, 0x3A548} includes terrain bonus
P.AS_OFFSET         = P.ATK_OFFSET +  4        -- {0x39270, 0x3A44E, 0x3A54A} 
P.HIT_OFFSET        = P.ATK_OFFSET + 10        -- {0x39276, 0x3A454, 0x3A550} if can't attack, = 0xFF
-- redundant with stat screen values
-- P.LUCK_OFFSET    = P.ATK_OFFSET + 14        -- {0x3927A, 0x3A458, 0x3A554}
P.CRIT_OFFSET       = P.ATK_OFFSET + 16        -- {0x3927C, 0x3A45A, 0x3A556}
-- P.LEVEL_OFFSET2  = {0x39280, 0x3A460, 0x3A55C} FE6
-- P.EXP_OFFSET2    = P.LEVEL_OFFSET2 + 1
-- NOT redundant with stat screen, that address may show post combat hp
P.CURR_HP_OFFSET    = {0x39282, 0x3A462, 0x3A55E}
P.CURR_HP_OFFSET = RAM_BASE + P.CURR_HP_OFFSET[GAME_VERSION - 5]

return P
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

P.SELECTED_SLOT  = {0x2AB76, 0x2BD48, 0x2BE4A} -- {,3A868,} even if not loaded as attacker todo FE6,8 validation
P.SELECTED_SLOT  = RAM_BASE + P.SELECTED_SLOT[GAME_VERSION - 5]

-- offsets are the same for slots, attacker, and defender
-- unit data occupies 0x48 (72) bytes per slot, followed by additional combat data for attacker/defender
-- enemy slots start at 129, other at 66? (FE7)
-- slots index from 1, not 0
P.SLOT_1_START   = {0x2AB78, 0x2BD50, 0x2BE4C}
P.SLOT_1_START   = RAM_BASE + P.SLOT_1_START[GAME_VERSION - 5]
P.ATTACKER_START = {0x39214, 0x3A3F0, 0x3A4EC}
P.ATTACKER_START = RAM_BASE + P.ATTACKER_START[GAME_VERSION - 5]
P.DEFENDER_START = {0x39290, 0x3A470, 0x3A56C}
P.DEFENDER_START = RAM_BASE + P.DEFENDER_START[GAME_VERSION - 5]

-- get values by slot
-- no need to reuse for attacker offsets, memory.readbyte(start + offset) is as concise and less indirection
function P.addrFromSlot(slot, offset)
	return P.SLOT_1_START + (slot - 1) * 72 + offset
end

function P.byteFromSlot(slot, offset)
	return memory.readbyte(P.addrFromSlot(slot, offset))
end

function P.wordFromSlot(slot, offset)
	return memory.readword(P.addrFromSlot(slot, offset))
end




P.NAME_CODE_OFFSET  =  0 -- {0x39214, 0x3A3F0, 0x3A4EC} 2 bytes
P.CLASS_CODE_OFFSET =  4 -- {0x39216, 0x3A3F2, 0x3A4EE} 2 bytes
P.LEVEL_OFFSET      =  8 -- {0x3921C, 0x3A3F8, 0x3A4F4} -- these update after combat
P.EXP_OFFSET        =  9 -- {0x3921D, 0x3A3F9, 0x3A4F5}
P.SLOT_ID_OFFSET    = 11 -- {0x3921F, 0x3A3FB, 0x3A4F7} index of data source

-- bitmap: 
-- 00000001 0x01 pending stop
-- 00000010 0x02 stopped via combat
-- 01000010 0x42 stopped via wait
-- 00010000 0x10 rescuing
-- 00100001 0x21 is rescued before moving
-- 00100011 0x23 is rescued after being taken or moving
P.MOVE_STATUS_OFFSET = 12 -- {,0x3A3FC,} --todo FE6,8

-- bitmap:
-- 00110010 0x32 Afa's?
-- 0001011? 0x16 and 0x17 Droppable item?
P.AFA_OFFSET         = 13 -- {,0x3A3FD,} --todo FE6,8

P.X_OFFSET = {14, 16, 16}   -- {0x39222, 0x3A400, 0x3A4FC} FE6 not aligned
P.X_OFFSET = P.X_OFFSET[GAME_VERSION - 5]
P.Y_OFFSET = P.X_OFFSET + 1 -- {0x39223, 0x3A401, 0x3A4FD}

P.MAX_HP_OFFSET = P.X_OFFSET + 2           -- {0x39224, 0x3A402, 0x3A4FE}
-- next is current hp, then 6 other stats on stat screen
-- "current" hp may be POST COMBAT hp on combat preview, even before rns consumed on player phase?....
-- 8 consecutive bytes

-- inventory list in 10 bytes, (item,uses) x5
P.ITEMS_OFFSET = P.MAX_HP_OFFSET + 12     -- {0x39230, 0x3A40E, 0x3A50A} 

P.RANKS_OFFSET = P.ITEMS_OFFSET + 10      -- {0x3923A, 0x3A418, 0x3A514}
-- status eg poison at + 8?

-- 10? consecutive bytes
P.SUPPORTS_OFFSET = P.RANKS_OFFSET + 10   -- {0x39244, 0x3A422, 0x3A51E}




-- check slots 1 to 32, return 0 if not found
function P.hoverPlayerSlot()
	for slotID = 1, 32 do
		if (P.byteFromSlot(slotID, P.X_OFFSET) == memory.readbyte(P.CURSOR_X)) and
		   (P.byteFromSlot(slotID, P.Y_OFFSET) == memory.readbyte(P.CURSOR_Y)) and 
		   not P.unitIsRescued(slotID) then
		   
		   return slotID
		end
	end
	return 0
end

function P.unitIsStopped(slot)
	return AND(P.byteFromSlot(slot, P.MOVE_STATUS_OFFSET), 2) > 0
end

function P.unitIsRescued(slot)
	return AND(P.byteFromSlot(slot, P.MOVE_STATUS_OFFSET), 32) > 0
end

function P.unitHasAfas(start)
	return (GAME_VERSION > 6) and (AND(memory.readbyte(start + addr.AFA_OFFSET), 32) > 0)
end

P.canAddAfas = (GAME_VERSION == 7 and memory.readbyte(P.CHAPTER) >= 31) or -- ch 31 == hector chapter 24
               (GAME_VERSION == 8) -- todo confirm chapter code for metis tome
P.SLOTS_TO_CHECK = 48
for slot = 1, addr.SLOTS_TO_CHECK do
	if P.unitHasAfas(P.addrFromSlot(slot, 0)) then
		P.canAddAfas = false -- use this to determine if stat up display should show ? for gains possible with Afa
		break
	end
end



-- post 72 bytes, only exist after attacker/defender

P.ATK_OFFSET           = P.SUPPORTS_OFFSET + 0x28 -- {0x3926C, 0x3A44A, 0x3A546} includes weapon triangle
P.DEF_OFFSET           = P.ATK_OFFSET +  2        -- {0x3926E, 0x3A44C, 0x3A548} includes terrain bonus
P.AS_OFFSET            = P.ATK_OFFSET +  4        -- {0x39270, 0x3A44E, 0x3A54A}
-- P.AVOID_OFFSET      = P.ATK_OFFSET +  8        -- {, 0x3A452, }
P.HIT_OFFSET           = P.ATK_OFFSET + 10        -- {0x39276, 0x3A454, 0x3A550} if can't attack, = 0xFF
-- P.CRIT_AVOID_OFFSET = P.ATK_OFFSET + 14        -- {0x3927A, 0x3A458, 0x3A554} includes supports (not tactician stars? == luck when no supports)
P.CRIT_OFFSET          = P.ATK_OFFSET + 16        -- {0x3927C, 0x3A45A, 0x3A556}

-- NOT redundant with stat screen, those update after combat so can't be used to auto construct ep combats
P.LEVEL2_OFFSET        = {4, 6, 6}                -- {0x39280, 0x3A460, 0x3A55C} -- FE6 not aligned
P.LEVEL2_OFFSET        = P.CRIT_OFFSET + P.LEVEL2_OFFSET[GAME_VERSION - 5]
P.EXP2_OFFSET          = P.LEVEL2_OFFSET + 1      -- {0x39281, 0x3A461, 0x3A55D}
P.CURR_HP_OFFSET       = P.LEVEL2_OFFSET + 2      -- {0x39282, 0x3A462, 0x3A55E}

return P
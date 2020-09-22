--https://gamefaqs.gamespot.com/gba/468480-fire-emblem/faqs/31542
--https://gamefaqs.gamespot.com/gba/921183-fire-emblem-the-sacred-stones/faqs/36978

-- 0x0203A3F0 FE7 portrait code/pointer, 2 bytes
-- 0x0203A3F4 FE7 portrait code/pointer
-- 0x0203A3FB FE7 team slot order


local P = {}
addr = P

GAME_VERSION = 7

-- 0,0 is upper left
P.CURSOR_X = {0x0202AA1C, 0x0202BBCC, 0x0202BCC4} -- also at +4
P.CURSOR_X = P.CURSOR_X[GAME_VERSION - 5]
P.CURSOR_Y = P.CURSOR_X + 2


return P
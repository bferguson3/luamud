dofile("src/preload.lua")
	
 sha  = require "sha2"
 enet = require "enet"
 json = require "json"
--local bit  = require "bit"

dofile("src/enums.lua")
dofile("src/packets.lua")
dofile("src/ansi.lua")
dofile("src/uid.lua")
dofile("src/c_character.lua")
dofile("src/item.lua")
dofile("src/monster.lua")
dofile("db/monster_db.lua")
dofile("db/item_db.lua")
dofile("db/treasure_db.lua")

host = enet.host_create()
server = nil --host:connect("localhost:6789")
ip_address = "localhost:6789"

-- Determine OS type for tty settings
local os_type = package.config:sub(1,1) == "\\" and "Windows" or "Unix-like"
if(os_type == "Unix-like")then
	os.execute("clear")
	os.execute("stty -icanon min 0 time 1 -echo")
else 
	os.execute("cls")
end

--USERNAME = "test"
--PASSWORD = "test"
 update_canvas = true
local fps_ctr = 0
local login_initialized = false 
local un_init = false 
-- love.update() 
--love.draw() 
local IS_SHIFT = false

local last_ping = 0
local delay = 0
 my_uid = make_UID()
local GAME_DONE = false

 active_character = nil 
 text_canvas = nil 

-- SCREEN mud_print STUFF
local TEXT_SPD = 10
local current_line = 0
local MAX_CHAR_WIDTH = 80
local MAX_CHAR_HEIGHT = 24
local intResolutionX = 640
local intResolutionY = 400
local current_col = 0
 text_buffer = {} -- what NEEDS to be printed next 
--char_ex = 
--    { c = 'a', x = 1, y = 2, r = {1.0, 0, 0} }
local font = nil 
 text_screen = {}
 screen = {}
--txt_char = { 'a', { 1, 0, 1 } }
local line_blink_spd = 0.1
local txt_blink_ctr = 0
local draw_cursor_line = false 
 current_input = ''
local cursor_pos_x = 0

CURRENT_GAME_STATE = GAMESTATE.LOGIN_SCREEN

local_enemies = {}

-- 
-- p () 
-- mud print 

-- seed 
math.randomseed(os.time())

active_character = nil 
 user_name_input=""
 my_uid = make_UID()

dofile("src/agno_cl.lua")


-- check_server coroutine
local delay = 0
local last_ping = 0.0
local multi_key = false
local last_keycode = 0

--
p("Input IP address, or press enter for localhost:6789.")
for i=1,22 do
	p(" ")
end

local time_since_last_key = 0
local actual_timer = 0
while not GAME_DONE do -- Main loop 
	actual_timer = actual_timer + 0.1
	-- this is inaccurate, but its very easy. 
	-- input 
	local _inp = io.read(1)
	if _inp ~= nil then 
		--print(string.byte(_inp))
		if(_inp == '\n')then -- return 
			moveto(0,25)
			io.write("                                                                              ")
			parse_input(current_input)
			current_input = ""
		elseif(string.byte(_inp) == 127)then -- backspace 
			current_input = string.sub(current_input, 1, #current_input - 1)
			moveto(0,25)
			io.write("                                                                              ")
			moveto(0,25)
		else 
			time_since_last_key = actual_timer
			current_input = current_input .. _inp
		end
	end
	
	-- ACTUAL SCREEN DRAW 
	if(actual_timer - time_since_last_key > 0.5)then
		update_screen = true 
		time_since_last_key = actual_timer
	end
	local prompt = get_prompt()
	if update_screen then 
		hide_cursor()
		topleft()
		local last_clr = 'fff'
		for y=1,24 do 
			for x=1,80 do 
				--if screen[(y*80)+x][2] ~= last_clr then -- change color 
				local s = string.lower(screen[(y*80)+x][2])
				color_hex(s)
				io.write(screen[(y*80)+x][1])
			end
			io.write("\n")
		end
		moveto(0,25)
		if CURRENT_GAME_STATE == GAMESTATE.GET_PASS then 
			local _tx = string.gsub(current_input, "%w", "*")
			io.write(_tx)
		else	
			io.write(prompt .. current_input)
		end
		update_screen = false 
		show_cursor()
	else  
		moveto(0,25)
		if CURRENT_GAME_STATE == GAMESTATE.GET_PASS then 
			local _tx = string.gsub(current_input, "%w", "*")
			io.write(_tx)
		else	
			io.write(prompt .. current_input)
		end
	end


	-- CHECK SERVER COROUTINE
	e = host:service(1) -- FAST AS U CAN. 1/10s? 
	if e then
		if e.type == "connect" then -- We connected, first event
			--p("Connected: " .. tostring(e.peer:connect_id()), {0.5,1,0.5}, false)
			--p("Enter your user name. (If it does not exist, it will be created.)")
		elseif e.type == "receive" then -- Standard msg event 
			process_packet(e)
		end
	end
	last_ping = os.time()
	delay = 0
end

server:disconnect()
host:flush()

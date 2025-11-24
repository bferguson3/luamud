-- love2d headless client 
local lg = love.graphics 
dofile = function(s) love.filesystem.load(s)() end

 sha = require("sha2")
--       local your_hash = sha.sha256("your string")
 enet = require "enet"
 json = require "json"
local bit = require "bit"

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
 ip_address="localhost:6789"
 server = nil 
local tty 

local os_type = package.config:sub(1,1) == "\\" and "Windows" or "Unix-like"
if(os_type == "Unix-like")then
    os.execute("clear")
	os.execute("stty -icanon min 0 time 1 -echo")
else 
    os.execute("cls")
	tty = require "tty"
end

USERNAME = "test"
PASSWORD = "test"

local last_ping = 0
local delay = 0

my_uid = make_UID()

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
 text_buffer = {}
screen = {}
--char_ex = 
--    { c = 'a', x = 1, y = 2, r = {1.0, 0, 0} }
--
local font = nil 
 text_screen = {}
--txt_char = { 'a', { 1, 0, 1 } }
-- }
local line_blink_spd = 0.1
local txt_blink_ctr = 0
local draw_cursor_line = false 
 current_input = ''
local cursor_pos_x = 0

 CURRENT_GAME_STATE = GAMESTATE.LOGIN_SCREEN

 local_enemies = {}
local update_screen = true 


screen = {}

math.randomseed(os.time())

for i=1,(80*25) do 
	screen[i] = { ' ', 'fff' }
end

-- TESTING 
local update_screen = true 
 user_name_input=""

dofile("src/agno_cl.lua")
--



function love.load()
    -- font = lg.newFont(8)

    -- text_canvas = lg.newCanvas(640, 400)

    math.randomseed(os.time())

    for i=1,(80*25) do -- insert screen as blank 
        table.insert(text_screen, { '', {1, 1, 1} } )
    end

end

local update_canvas = true
local fps_ctr = 0
local login_initialized = false 
local un_init = false 


local IS_SHIFT = false


-------------------------------------------------
--
--     LOVE CODE 
-- 
-------------------------------------------------
local time_since_last_key = 0
local actual_timer = 0
function love.update(dt)
    actual_timer = actual_timer + 0.1
    if(dt < 1/30) then love.timer.sleep((1/30) - dt) end

    local e = nil 
    local _inp = nil 
    txt_blink_ctr = txt_blink_ctr + dt
    if tty then 
        _inp = tty.read_chr()
        --logprint(_inp)
        if (_inp == 0) then _inp = nil end 
        if (_inp == 13) then _inp = "\n" else
            if _inp ~= nil then 
                _inp = string.char(tonumber(_inp))
            end
        end
    else 
        _inp = io.read(1)
    end
	if _inp ~= nil then 
		--print(string.byte(_inp)) -- debug 
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
            --logprint(current_input)
		end
	end


    if CURRENT_GAME_STATE == GAMESTATE.NORMAL_GAME then 
        -- CHECK SERVER 
        e = host:service(1)
        if e then
            if e.type == "connect" then -- We connected, first event
                p("%raaaConnected: %rfff")
                p(tostring(e.peer:connect_id()))
                --login = LoginPacket:new({uid=my_uid, login=USERNAME, pass=PASSWORD})
                --e.peer:send(json.encode(login))
            elseif e.type == "receive" then -- Standard msg event 
                process_packet(e)
            end
        end
    
    elseif CURRENT_GAME_STATE == GAMESTATE.LOGIN_SCREEN then 
        -- First, process login 
        if(login_initialized==false)then 
            p("%rf77Welcome to SworldMud!")
            p("Please input the IP address of your server, or\nENTER to use localhost:6789.")
            login_initialized = true 
        end
    
    elseif CURRENT_GAME_STATE == GAMESTATE.GET_USER then 
        if not un_init then 
            p("OK! Please enter your USERNAME: \n (If it does not exist on the server, it will be created)")
            un_init = true
        end
    
    elseif CURRENT_GAME_STATE == GAMESTATE.QUIT then 
        --love.event.quit()

    end
    
    -- process text buffer 
    for _i=1,TEXT_SPD do
        if #text_buffer > 0 then 
            text_screen[(text_buffer[1].y * 80) + text_buffer[1].x] = { text_buffer[1].c, text_buffer[1].r }
            table.remove(text_buffer, 1)
            update_canvas = true 
        end
    end

    -- DRAW
    --
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
        hide_cursor()
		moveto(0,25)
		if CURRENT_GAME_STATE == GAMESTATE.GET_PASS then 
			local _tx = string.gsub(current_input, "%w", "*")
			io.write(_tx)
		else	
			io.write(prompt .. current_input)
		end
        show_cursor()
	end

    if CURRENT_GAME_STATE == GAMESTATE.QUIT then 
        love.event.quit()
    end
end

function love.quit()
    if server ~= nil then 
        server:send(json.encode({type="LOGOUT", uid=my_uid}))
        host:service(1)
        --server:disconnect()
        host:flush()
    end
    --tty.disable_raw_mode()
    return false -- false = do not abort quit()
end
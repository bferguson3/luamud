-- love2d headless client 
local lg = love.graphics 
dofile = love.filesystem.load

local sha = require("sha2")
--       local your_hash = sha.sha256("your string")
local enet = require "enet"
local json = require "json"
local bit = require "bit"
--local tick = require 'tick'
dofile("src/enums.lua")()
dofile("src/packets.lua")()
dofile("src/ansi.lua")()
dofile("src/uid.lua")()
dofile("src/c_character.lua")()
dofile("src/item.lua")()
local host = enet.host_create()
local ip_address="localhost:6789"
local server = nil 
local tty 

local os_type = package.config:sub(1,1) == "\\" and "Windows" or "Unix-like"
if(os_type == "Unix-like")then
	os.execute("stty -icanon min 0 time 1 -echo")
else 
	tty = require "tty"
end

USERNAME = "test"
PASSWORD = "test"

local last_ping = 0
local delay = 0
local my_uid = make_UID()

local active_character = nil 
local text_canvas = nil 

-- SCREEN mud_print STUFF
local TEXT_SPD = 10
local current_line = 0
local MAX_CHAR_WIDTH = 80
local MAX_CHAR_HEIGHT = 24
local intResolutionX = 640
local intResolutionY = 400
local current_col = 0
local text_buffer = {}
--char_ex = 
--    { c = 'a', x = 1, y = 2, r = {1.0, 0, 0} }
--
local font = nil 
local text_screen = {}
--txt_char = { 'a', { 1, 0, 1 } }
-- }
local line_blink_spd = 0.1
local txt_blink_ctr = 0
local draw_cursor_line = false 
local current_input = ''
local cursor_pos_x = 0

local CURRENT_GAME_STATE = GAMESTATE.LOGIN_SCREEN

local local_enemies = {}
local update_screen = true 


screen = {}

math.randomseed(os.time())

for i=1,(80*25) do 
	screen[i] = { ' ', 'fff' }
end

-- TESTING 
local update_screen = true 

function logprint(st)
	local f = io.open("log.txt", "a")
	f:write(st)
	f:close()
end

function color_hex(s)
	if s == 'ff0' then 
		io.write(BRK .. CLR .. ansi_colors.YELLOW .. "m")
	elseif s == '00f' then 
		io.write(BRK .. CLR .. ansi_colors.BLUE .. "m")
	elseif s == 'afa' then 
		io.write(BRK .. CLR .. ansi_colors.CYAN .. "m")
	elseif s == 'aaa' then 
		io.write(BRK .. CLR .. ansi_colors.WHITE .. "m")
	elseif s == 'd4d' then 
		io.write(BRK .. CLR .. ansi_colors.MAGENTA .. "m")
	elseif s == 'fff' then 
		io.write(BRK .. CLR .. ansi_colors.BRWHITE .. "m")
	elseif s == '999' then 
		io.write(BRK .. CLR .. ansi_colors.WHITE .. "m")
	elseif s == '0f2' then 
		io.write(BRK .. CLR .. ansi_colors.GREEN .. "m")
	elseif s == '0fb' then 
		io.write(BRK .. CLR .. ansi_colors.CYAN .. "m")
	elseif s == 'f99' then 
		io.write(BRK .. CLR .. ansi_colors.RED .. "m")
	elseif s == 'f88' then 
		io.write(BRK .. CLR .. ansi_colors.RED .. "m")
	end
end
--print = logprint

function split(s, delimiter)
    local result = {}
    -- Pattern matches any character not in the delimiter set, one or more times
    for part in string.gmatch(s, "([^" .. delimiter .. "]+)") do
        table.insert(result, part)
    end
    return result
end

function ansicolor(c)
	if c ~= nil then 
		io.write("\x1b[0;" .. c .. "m")		
	else -- bright white
		io.write("\x1b[0;97m")
	end
end

clrcode = "%%[Rr][0123456789ABCDEFabcdef][0123456789ABCDEFabcdef][0123456789ABCDEFabcdef]"		


function mud_print(txt, _color, _newline)
    update_screen = true
	-- print as much as fits 
	local parts = split(txt, '\n')
	local clr = 'fff'
	for i=1,#parts do 
		logprint(os.time() .. " : ") -- this is linux time in seconds 
		logprint(parts[i])
		logprint("\n")
	end
	for i=1,#parts do 
		for y=1,24 do
			for x=1,80 do  
				screen[((y*80)+x)-80] = screen[(y*80)+x]
			end
		end
		local y = (24 * 80) + 1
		while y < ((24 * 80) + 80) do 
			screen[y] = { ' ', 'fff' }
			y = y + 1
		end
		-- replace all color codes with ansi codes instead 
		-- TODO: do this differently by colorizing each code in ram 
		local c = 1 
		local l = (24*80)+1
		while c <= #parts[i] do 
			local _s = parts[i]:sub(c,c)
			if _s == '%' then 
				if parts[i]:sub(c+1, c+1) == 'r' then 
					clr = parts[i]:sub(c+2,c+4)
					_s = parts[i]:sub(c+5,c+5)
					c = c + 5
				end
			end
			screen[l] = { _s, clr }
			c = c + 1 
			l = l + 1 
		end
		while c <= 80 do 
			screen[l] = { ' ', 'fff' }
			c = c + 1
			l = l + 1
		end
	end
end
local p = mud_print

--
local user_name_input=""

function parse_input(f)
	f = string.lower(f)
    if CURRENT_GAME_STATE==GAMESTATE.NORMAL_GAME then 
    -- COMMAND INPUT PROCESSING 
    -- 
        -- ATTACK COMMAND 
        if string.find(f, "att") == 1 then 
            tgt = ""
            tgt_i = 0
            for k,v in pairs(local_enemies) do 
                for token in string.gmatch(f, "[^%s]+") do 
                    if tonumber(token) then 
                        tgt = local_enemies[tonumber(token)]
                        tgt_i = tonumber(token)
                    else
                        if #token < 3 then 
                            p("Attack who?")
                            return 
                        end
                        if string.find(string.lower(v.name), token) then 
                            tgt_i = k
                            tgt = v
                        else
                            tgt = nil 
                        end
                    end
                end
                if tgt ~= nil then 
                    break 
                end
            end
            if tgt ~= nil then 
                --p(tgt.name)
                p("You attack " .. tgt.name .. "!")
                server:send(json.encode(CommandPacket:new({uid=my_uid, cmd="ATTACK", loc=active_character.location, tgt=tgt_i})))
            else
                p("No target!")
            end

        -- LOOK COMMAND 
        elseif string.find(f, "loo") == 1 or f == "l" then 
            p("Looking around, you see:")
            server:send(json.encode(CommandPacket:new({uid=my_uid, cmd="LOOK", loc=active_character.location})))
        
        -- SAY 
        elseif string.find(f, "say ") == 1 or string.sub(f, 1, 1) == "\"" then 
            local d = ""
            if string.find(f, "say ") == 1 then 
                d = string.sub(f, 5, #f)
            else -- "
                d = string.sub(f, 2, #f)
            end
            server:send(json.encode(CommandPacket:new({uid=my_uid, cmd="SAY", txt=d})))

        -- QUIT / EXIT 
        elseif string.find(f, "quit") == 1 or string.find(f, "exit") == 1 then 
            server:send(json.encode({type="LOGOUT",uid=my_uid}))
            love.event.quit()

        -- HEALME (cheat)
        elseif(string.find(string.lower(f), "healme") == 1) then 
			server:send(json.encode(CommandPacket:new({uid=my_uid, cmd="HEALME"})))


        -- USE (generic)
        elseif string.find(f, "use") == 1 then 
            local d = string.sub(f, 5, #f) 

            local used = false

            -- Use Decoy Attk 
            if string.find(d, "decoy") == 1 then 
                for i=1,#active_character.feats do 
                    if active_character.feats[i] == FEATS.DecoyAttackI then 
                        server:send(json.encode(CommandPacket:new({uid=my_uid, cmd="USE", txt="Decoy Attack I"})))
                        used = true
                        break
                    elseif active_character.feats[i] == FEATS.DecoyAttackII then  
                        server:send(json.encode(CommandPacket:new({uid=my_uid, cmd="USE", txt="Decoy Attack II"})))
                        used = true
                        break
                    end 
                end
            end

            if not used then 
                p("Use what?")
            end

        --
        end
    elseif CURRENT_GAME_STATE == GAMESTATE.LOGIN_SCREEN then 
        ip_address = f 
        --logprint(f)
        if ip_address == "" then ip_address = "192.168.1.5:6789" end 
        server = host:connect(ip_address)
        if server == nil then 
            p("Failed to connect!")
        else
            e = host:service(250)
            if(e)then
                if e.type=="connect"then 
                    p("Connected: ", '999', false)
                    p(tostring(e.peer:connect_id()))
                    CURRENT_GAME_STATE = GAMESTATE.GET_USER
                end
            else 
                p("Connection failed.")
                CURRENT_GAME_STATE = GAMESTATE.QUIT
            end
        end
    elseif CURRENT_GAME_STATE==GAMESTATE.GET_USER then 
        user_name_input = f:gsub("%s+", "")
        user_name_input = user_name_input:gsub("[^%w+]", "")
        if user_name_input:len() <= 16 then 
            p(user_name_input .. ": Please enter your PASSWORD")
            CURRENT_GAME_STATE=GAMESTATE.GET_PASS
        else
            p("User name too long. Max 16 characters")
            un_init = false 
            CURRENT_GAME_STATE=GAMESTATE.GET_USER
        end
    elseif CURRENT_GAME_STATE==GAMESTATE.GET_PASS then 
        if(f:len()>64)then
            p("Password too long. Max 64 characters. Try again: ")
        elseif(f:len()<6)then 
            p("Password too short. Minimum 6 characters. Try again: ")
        else
            password_input = sha.sha256(f)
            login = LoginPacket:new({uid=my_uid, login=user_name_input, pass=password_input})
            server:send(json.encode(login))
            CURRENT_GAME_STATE=GAMESTATE.NORMAL_GAME
        end
    end
end

--

function process_packet(e)
	-- e = event object 
	local pak = json.decode(e.data)

	if pak.type == "CHARACTER_DAT" then 
		p("new character data received", {1, 0.2, 0.2})
		active_character = Character:new({})
		active_character.from_blob(pak.character)
		p(active_character.name)
		p("DEX   " .. active_character.dex)
		p("AGI   " .. active_character.agi)
		p("STR   " .. active_character.str)
		p("VIT   " .. active_character.vit)
		p("INT   " .. active_character.int)
		p("SPI   " .. active_character.spi)
		p("")
        
    elseif pak.type == "ROOM" then 
        p("-[" .. pak.name .. "]-", {1,1,0.5})
        p(pak.desc)
        p("You also see:")
        for k,v in pairs(pak.mobs) do 
            p(k .. " " .. v)
            local_enemies[k] = { name = "" }
            local_enemies[k].name = v 
        end
        for k,v in pairs(pak.current_players)do
            if(v ~= active_character.name)then
                p(v .. " %rafa(Player)")
            end
        end

    elseif pak.type == "MESSAGE_COMBAT" then    
        p(pak.msg)
        -- for each character, process any codes etc before adding directly to print queue
    else
        print(pak.type)
    end
end


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
        e = host:service()
        if e then
            if e.type == "connect" then -- We connected, first event
                p("Connected: ", {0.5,1,0.5}, false)
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
            p("%rff8Welcome to SworldMud!")
            p("Please input the IP address of your server, or\nENTER to use localhost:6789.")
            login_initialized = true 
        end
    
    elseif CURRENT_GAME_STATE == GAMESTATE.GET_USER then 
        if not un_init then 
            p("OK! Please enter your USERNAME: \n (If it does not exist on the server, it will be created)")
            un_init = true
        end
    
    elseif CURRENT_GAME_STATE == GAMESTATE.QUIT then 
        love.event.quit()

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
	--update_screen = true
	if update_screen then 
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
		--print("")
		if CURRENT_GAME_STATE == GAMESTATE.GET_PASS then 
			local _tx = string.gsub(current_input, "%w", "*")
			io.write(_tx)
		else	
			io.write("> " .. current_input)
		end
		update_screen = false 
	else  
		moveto(0,25)
		if CURRENT_GAME_STATE == GAMESTATE.GET_PASS then 
			local _tx = string.gsub(current_input, "%w", "*")
			io.write(_tx)
		else	
			io.write("> " .. current_input)
		end
	end
    -- draw text screen to canvas during main loop 
    --print("hello world")
    -- if(update_canvas)then
    -- lg.setCanvas(text_canvas)
    --     lg.clear(0.1, 0.1, 0.1)
    --     for y=0,24 do
    --         for x=0,80 do 
    --             if(text_screen[(y*80)+x] ~= nil) then 
    --                 lg.setColor(text_screen[(y*80)+x][2])
    --                 lg.print(text_screen[(y*80)+x], x * 8, y * 16)
    --             end
    --         end
    --     end
    -- lg.setCanvas()
    -- update_canvas = false 
    -- end
    -- --
    --

    -- flicker txt line 
    if txt_blink_ctr > line_blink_spd then 
        if draw_cursor_line == false then 
            draw_cursor_line = true 
        else 
            draw_cursor_line = false 
        end
        txt_blink_ctr = 0
    end

    --parse_input("")	
end

function love.quit()
    if server ~= nil then 
        server:send(json.encode({type="LOGOUT", uid=my_uid}))
        host:service()
        --server:disconnect()
        host:flush()
    end
    --tty.disable_raw_mode()
    return false -- false = do not abort quit()
end
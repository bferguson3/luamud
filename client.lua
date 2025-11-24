dofile("src/preload.lua")
	
local sha  = require "sha2"
local enet = require "enet"
local json = require "json"
local bit  = require "bit"
dofile("src/enums.lua")
dofile("src/packets.lua")
dofile("src/ansi.lua")
dofile("src/uid.lua")
dofile("src/c_character.lua")
-- huh? why need this 
dofile("src/monster.lua")
dofile("src/item.lua")
local host = enet.host_create()
local server = nil --host:connect("localhost:6789")
local ip_address = "localhost:6789"

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
local update_canvas = true
local fps_ctr = 0
local login_initialized = false 
local un_init = false 
-- love.update() 
--love.draw() 
local IS_SHIFT = false

local last_ping = 0
local delay = 0
local my_uid = make_UID()
local GAME_DONE = false

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
local text_buffer = {} -- what NEEDS to be printed next 
--char_ex = 
--    { c = 'a', x = 1, y = 2, r = {1.0, 0, 0} }
local font = nil 
local text_screen = {}
--txt_char = { 'a', { 1, 0, 1 } }
local line_blink_spd = 0.1
local txt_blink_ctr = 0
local draw_cursor_line = false 
local current_input = ''
local cursor_pos_x = 0

local CURRENT_GAME_STATE = GAMESTATE.LOGIN_SCREEN

local local_enemies = {}

-- 
-- p () 
-- mud print 

-- seed 
math.randomseed(os.time())

local active_character = nil 
local user_name_input=""

function parse_input(f)
	--f = string.lower(f)
    if CURRENT_GAME_STATE==GAMESTATE.NORMAL_GAME then 
    -- COMMAND INPUT PROCESSING 
    -- 
        -- ATTACK COMMAND 
        if string.find(f, "att") == 1 then 
            local tgt = ""
            local tgt_i = 0
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
		
		elseif(string.find(string.lower(f), "stat") == 1) then 
			server:send(json.encode(CommandPacket:new({cmd="GET_STATUS",uid=my_uid})))

		-- exit_quit 
		elseif(string.find(string.lower(f), "exit") == 1) then 
			server:send(json.encode({type="LOGOUT",uid=my_uid}))
			--GAME_DONE = true

		elseif(string.find(string.lower(f), "quit") == 1) then 
			server:send(json.encode({type="LOGOUT",uid=my_uid}))
			--GAME_DONE = true 

		-- emergency heal 
		elseif(string.find(string.lower(f), "healme") == 1) then 
			server:send(json.encode(CommandPacket:new({uid=my_uid, cmd="HEALME"})))

        -- LOOK COMMAND 
        elseif string.find(string.lower(f), "loo") == 1 or f == "l" then 
            p("Looking around, you see:")
            server:send(json.encode(CommandPacket:new({uid=my_uid, cmd="LOOK", loc=active_character.location})))
        
        -- SAY 
        elseif string.find(string.lower(f), "say ") == 1 or string.sub(f, 1, 1) == "\"" then 
            local d = ""
            if string.find(string.lower(f), "say ") == 1 then 
                d = string.sub(f, 5, #f)
            else -- "
                d = string.sub(f, 2, #f)
            end
            server:send(json.encode(CommandPacket:new({uid=my_uid, cmd="SAY", txt=d})))

        -- USE (generic)
        elseif string.find(string.lower(f), "use") == 1 then 
            local d = string.sub(f, 5, #f) 

            local used = false

            -- Use Decoy Attk 
            if string.find(string.lower(d), "decoy") == 1 then 
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
        if ip_address == "" then ip_address = "localhost:6789" end 
        server = host:connect(ip_address)
		if server == nil then 
			p("Failed to connect!")
        else
			e = host:service(250)
            if(e)then
				print("service ok ")
                if e.type=="connect"then 
                    p("Connected: " .. tostring(e.peer:connect_id()), '7f7', false)
                    p("Enter your user name. (If it does not exist, it will be created.)")
                    CURRENT_GAME_STATE = GAMESTATE.GET_USER
                end    
            else 
				print("no event", server)
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
        if(f:len() > 64)then
            p("Password too long. Max 64 characters. Try again: ")
        elseif(f:len() < 6)then 
            p("Password too short. Minimum 6 characters. Try again: ")
        else
            local password_input = sha.sha256(f)
            local login = LoginPacket:new({uid=my_uid, login=user_name_input, pass=password_input})
            server:send(json.encode(login))
            CURRENT_GAME_STATE=GAMESTATE.NORMAL_GAME
        end
    end
end

--
-- function love.load() 
	-- 
--love.keypressed()
--resize 
--quit 


function process_packet(e)
	-- e = event object 
	local pak = json.decode(e.data)
	
	if pak.type == "CHARACTER_DAT" then 
		active_character = Character:new({})
		active_character.from_blob(pak.character)
		active_character.p_status()
	
	elseif pak.type == "CHARACTER_UPDATE" then  -- Do not print!
		active_character = Character:new({})
		active_character.from_blob(pak.character)
        
    elseif pak.type == "ROOM" then 
        p("-[" .. pak.name .. "]-", 'ff7' )
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

	elseif pak.type == "DISCONNECT_OK" then 
        print(pak.msg)
        os.exit()

    else
        p(pak.type)
    end
end

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

--print = logprint

function split(s, delimiter)
    local result = {}
    -- Pattern matches any character not in the delimiter set, one or more times
    for part in string.gmatch(s, "([^" .. delimiter .. "]+)") do
        table.insert(result, part)
    end
    return result
end


clrcode = "%%[Rr][0123456789ABCDEFabcdef][0123456789ABCDEFabcdef][0123456789ABCDEFabcdef]"		

function p(txt, color, newline)
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
	--ansicolor()
end

local my_uid = make_UID()

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
	local prompt = ""
	if active_character then 
		--prompt = " \x1b[0;91m" .. active_character.cur_hp .. "\x1b[0;97m / \x1b[0;91m" .. active_character.hp .. "\x1b[0;97m > "
		prompt = " HP \x1b[0;91m" .. active_character.cur_hp .. "\x1b[0;97m MP \x1b[0;96m" .. active_character.cur_mp .. "\x1b[0;97m > "
	else 
		prompt = "> "
	end
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
		if CURRENT_GAME_STATE == GAMESTATE.GET_PASS then 
			local _tx = string.gsub(current_input, "%w", "*")
			io.write(_tx)
		else	
			io.write(prompt .. current_input)
		end
		update_screen = false 
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

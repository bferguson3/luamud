
function parse_input(f)
	local lf = string.lower(f)
    if CURRENT_GAME_STATE==GAMESTATE.NORMAL_GAME then 
    -- COMMAND INPUT PROCESSING 
    -- 
        if string.find(lf, "move ") == 1 then -- we just ignore it :)
            f = string.sub(f, 6, #f)
            lf = string.lower(f)
        end

        -- ATTACK COMMAND 
        if string.find(lf, "att") == 1 then 
            local tgt = ""
            local tgt_i = 0
            for k,v in pairs(local_enemies) do  -- try to find it intelligently by name 
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
                p("You attack " .. tgt.name .. "!")
                server:send(json.encode(CommandPacket:new({uid=my_uid, cmd=COMMANDS.Attack, loc=active_character.location, tgt=tgt_i})))
            else
                p("No target!")
            end
		

        -- STATUS 
		elseif(string.find(lf, "stat") == 1) then 
			server:send(json.encode(CommandPacket:new({cmd=COMMANDS.GetStatus,uid=my_uid})))



		-- exit_quit 
		elseif(string.find(lf, "exit") == 1) then 
			server:send(json.encode({type="LOGOUT",uid=my_uid}))
			--GAME_DONE = true
		elseif(string.find(lf, "quit") == 1) then 
			server:send(json.encode({type="LOGOUT",uid=my_uid}))
			--GAME_DONE = true 



		-- emergency heal 
		elseif(string.find(lf, "healme") == 1) then 
			server:send(json.encode(CommandPacket:new({uid=my_uid, cmd=COMMANDS.HealMe})))



        -- LOOK COMMAND 
        elseif string.find(lf, "loo") == 1 or f == "l" then 
            p("Looking around, you see:")
            server:send(json.encode(CommandPacket:new({uid=my_uid, cmd=COMMANDS.Look, loc=active_character.location})))
        


        -- SEARCH 
        elseif string.find(lf, "sear") == 1 then 
            server:send(json.encode(CommandPacket:new({uid=my_uid, cmd=COMMANDS.Search, loc=active_character.location})))



        -- TALK 
        elseif string.find(lf, "talk") == 1 then 
            server:send(json.encode(CommandPacket:new({uid=my_uid, cmd=COMMANDS.Talk, loc=active_character.location})))



        -- MOVE 
        elseif lf == "n" or lf == "north" then 
            p("You move north.")
            server:send(json.encode(CommandPacket:new({uid=my_uid, src=active_character.location, cmd=COMMANDS.Move, dir=EXITS.N})))
        elseif lf == "s" or lf == "south" then 
            p("You move south.")
            server:send(json.encode(CommandPacket:new({uid=my_uid, src=active_character.location, cmd=COMMANDS.Move, dir=EXITS.S})))
        elseif lf == "e" or lf == "east" then 
            p("You move east.")
            server:send(json.encode(CommandPacket:new({uid=my_uid, src=active_character.location, cmd=COMMANDS.Move, dir=EXITS.E})))
        elseif lf == "w" or lf == "west" then 
            p("You move west.")
            server:send(json.encode(CommandPacket:new({uid=my_uid, src=active_character.location, cmd=COMMANDS.Move, dir=EXITS.W})))
        elseif lf == "u" or lf == "up" then 
            p("You ascend.")
            server:send(json.encode(CommandPacket:new({uid=my_uid, src=active_character.location, cmd=COMMANDS.Move, dir=EXITS.U})))
        elseif lf == "d" or lf == "down" then 
            p("You descend.")
            server:send(json.encode(CommandPacket:new({uid=my_uid, src=active_character.location, cmd=COMMANDS.Move, dir=EXITS.D})))
        elseif lf == "nw" or lf == "northwest" then 
            p("You head northwest.")
            server:send(json.encode(CommandPacket:new({uid=my_uid, src=active_character.location, cmd=COMMANDS.Move, dir=EXITS.NW})))
        elseif lf == "ne" or lf == "northeast" then 
            p("You head northeast.")
            server:send(json.encode(CommandPacket:new({uid=my_uid, src=active_character.location, cmd=COMMANDS.Move, dir=EXITS.NE})))
        elseif lf == "sw" or lf == "southwest" then 
            p("You head southwest.")
            server:send(json.encode(CommandPacket:new({uid=my_uid, src=active_character.location, cmd=COMMANDS.Move, dir=EXITS.SW})))
        elseif lf == "se" or lf == "southeast" then     
            p("You head southeast.")
            server:send(json.encode(CommandPacket:new({uid=my_uid, src=active_character.location, cmd=COMMANDS.Move, dir=EXITS.SE})))



        -- SAY 
        elseif string.find(lf, "say ") == 1 or string.sub(f, 1, 1) == "\"" then 
            local d = ""
            if string.find(lf, "say ") == 1 then 
                d = string.sub(f, 5, #f)
            else -- "
                d = string.sub(f, 2, #f)
            end
            server:send(json.encode(CommandPacket:new({uid=my_uid, cmd=COMMANDS.Say, txt=d})))


        -- HELP 
        elseif string.find(lf, "help")==1 then 
            if #lf > 5 then 
                local b = lf:sub(6,#lf)
                for k,v in pairs(COMMANDS) do 
                    if string.find(string.lower(v), b)==1 then 
                        p("%r770" .. v .. "%rfff")
                        p(CMD_DESCRIPTIONS[v])
                        break
                    end
                end
            else
                local _s = "" 
                local ct = 0
                for k,v in pairs(COMMANDS) do 
                    _s = _s .. v .. ", "
                    ct = ct + 1
                    if ct == 6 then 
                        _s = _s .. "\n "
                        ct = 0
                    end
                end
                p("The following commands were found:\n " .. _s:sub(1,#_s-2))
                p(" For more information, try HELP (command), e.g. HELP ATTACK")
            end


        -- USE (generic)
        elseif string.find(lf, "use") == 1 then 
            local d = string.sub(f, 5, #f) 

            local used = false

            -- Use Decoy Attk 
            if string.find(string.lower(d), "decoy") == 1 then 
                for i=1,#active_character.feats do 
                    if active_character.feats[i] == FEATS.DecoyAttackI then 
                        server:send(json.encode(CommandPacket:new({uid=my_uid, cmd=COMMANDS.Use, txt="Decoy Attack I"})))
                        used = true
                        break
                    elseif active_character.feats[i] == FEATS.DecoyAttackII then  
                        server:send(json.encode(CommandPacket:new({uid=my_uid, cmd=COMMANDS.Use, txt="Decoy Attack II"})))
                        used = true
                        break
                    end 
                end
            end

            if not used then 
                p("Use what?")
            end

        --
        else 
            
            p("I didn't understand that.")

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

function get_exit_string(e)
    if e == EXITS.D then return "down"
    elseif e == EXITS.U then return "up"
    elseif e == EXITS.N then return "north"
    elseif e == EXITS.S then return "south"
    elseif e == EXITS.E then return "east"
    elseif e == EXITS.W then return "west"
    elseif e == EXITS.NE then return "northeast"
    elseif e == EXITS.NW then return "northwest"
    elseif e == EXITS.SE then return "southeast"
    elseif e == EXITS.SW then return "southwest"
    end
end


function process_packet(e)
	-- e = event object 
	local pak = json.decode(e.data)
	
	if pak.type == "CHARACTER_DAT" then 
        active_character = Character:new({})
		active_character.from_blob(pak.character)
		active_character.p_status()
        
	elseif pak.type == "CHARACTER_UPDATE" then  -- Do not print!
        local _l = active_character.location 
		active_character = Character:new({})
		active_character.from_blob(pak.character)
        active_character.location = _l 
        
    elseif pak.type == "ROOM" then 
        p(" ")
        p("-[" .. pak.name .. "]-", 'ff7' )
        p(pak.desc)
        local _estr = ""
        for i=1,#pak.exits do
            if pak.exits[i] == 1 then  
                _estr = _estr .. get_exit_string(i) .. ", "
            end
        end
        if #_estr > 2 then _estr = _estr:sub(1, #_estr - 2) end-- trim last , 
        if _estr == "" then 
            p("There are no exits.")
        else 
            p("%rafaExits: %r999" .. _estr .. "%rfff")
        end
        p(" \nYou also see:")
        local_enemies = {}
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
        p(" ")
        active_character.location = pak.index 

    elseif pak.type == "MESSAGE_COMBAT" then    
        p(pak.msg)
        -- for each character, process any codes etc before adding directly to print queue

	elseif pak.type == "DISCONNECT_OK" then 
        p(pak.msg)
        CURRENT_GAME_STATE = GAMESTATE.QUIT 

    else
        p("Client error: Unsupported packet type " .. pak.type)
    end
end


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

function get_prompt()
    local prompt
    if active_character then 
		--prompt = " \x1b[0;91m" .. active_character.cur_hp .. "\x1b[0;97m / \x1b[0;91m" .. active_character.hp .. "\x1b[0;97m > "
		prompt = " HP \x1b[0;91m" .. active_character.cur_hp .. "\x1b[0;97m MP \x1b[0;96m" .. active_character.cur_mp .. "\x1b[0;97m > "
	else 
		prompt = "> "
	end
    return prompt 
end

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

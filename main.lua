-- love2d client 
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

GAMESTATE={
    LOGIN_SCREEN = 1,
    NORMAL_GAME = 2,
    GET_IP = 3,
    GET_USER=4,
    GET_PASS=5
}
local CURRENT_GAME_STATE = GAMESTATE.LOGIN_SCREEN

local local_enemies = {}


function mud_print(txt, _color, _newline)
    local txt = txt or ""
    local _newline = _newline or true 
    local _color =_color or {1, 1, 1}
    if _newline == false then _newline = 2 end 
    if txt==nil then 
        return 
    end
    for i=1,#txt do
        local _c = string.sub(txt, i, i)
        if _c == '\n' then 
            current_line = current_line + 1
            current_col = 0
            if current_line > MAX_CHAR_HEIGHT then 
                current_line = current_line - 1
                for _i=MAX_CHAR_WIDTH,#text_screen do 
                    text_screen[_i - MAX_CHAR_WIDTH] = text_screen[_i]
                end
                for _i=1,#text_buffer do 
                    text_buffer[_i].y = text_buffer[_i].y - 1
                end
            end
        elseif _c == '%' then 
            -- special code 
            if string.sub(txt, i, i+1) == '%r' then -- change color 
                local _lr = string.sub(txt, i+2, i+4)
                _color={tonumber(string.sub(_lr,1,1),16)/15,
                    tonumber(string.sub(_lr,2,2),16)/15,
                    tonumber(string.sub(_lr,3,3),16)/15}
                txt = string.sub(txt, 1, i-1) .. string.sub(txt, i+4, #txt)
            end
        else
            table.insert(text_buffer, { c = _c, x = current_col, y = current_line, r = _color} )
            current_col = current_col + 1
        end
    end
    
    if _newline~=2 then 
        current_col = 0
        current_line = current_line + 1
        
        if current_line > MAX_CHAR_HEIGHT then 
            current_line = current_line - 1
            for _i=MAX_CHAR_WIDTH,#text_screen do 
                text_screen[_i - MAX_CHAR_WIDTH] = text_screen[_i]
            end
            for _i=1,#text_buffer do 
                text_buffer[_i].y = text_buffer[_i].y - 1
            end
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
        if ip_address == "" then ip_address = "localhost:6789" end 
        server = host:connect(ip_address)
        if server == nil then 
            p("Failed to connect!")
        else
            e = host:service(250)
            if(e)then
                if e.type=="connect"then 
                    p("Connected: ", {0.5,1,0.5}, false)
                    p(tostring(e.peer:connect_id()))
                    CURRENT_GAME_STATE = GAMESTATE.GET_USER
                end    
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
    font = lg.newFont(8)

    text_canvas = lg.newCanvas(640, 400)

    math.randomseed(os.time())

    for i=1,(80*25) do -- insert screen as blank 
        table.insert(text_screen, { '', {1, 1, 1} } )
    end

end

local update_canvas = true
local fps_ctr = 0
local login_initialized = false 
local un_init = false 
function love.update(dt)
    if(dt < 1/30) then love.timer.sleep((1/30) - dt) end

    local e = nil 

    txt_blink_ctr = txt_blink_ctr + dt

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
    -- draw text screen to canvas during main loop 
    if(update_canvas)then
    lg.setCanvas(text_canvas)
        lg.clear(0.1, 0.1, 0.1)
        for y=0,24 do
            for x=0,80 do 
                if(text_screen[(y*80)+x] ~= nil) then 
                    lg.setColor(text_screen[(y*80)+x][2])
                    lg.print(text_screen[(y*80)+x], x * 8, y * 16)
                end
            end
        end
    lg.setCanvas()
    update_canvas = false 
    end
    --
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
		
end

function love.draw()

    lg.clear(0, 0, 0) -- cls 
    
    scaleX = intResolutionX / 640
    scaleY = intResolutionY / 400
    lg.draw(text_canvas, 0, 0, 0, scaleX, scaleY) -- screen

    lg.setColor(1, 1, 1)
    lg.line(0, (400-16)*scaleY, 640*scaleX, (400-16)*scaleY) -- input rule 

    lg.print("> ", 0, (400-16)*scaleY, 0, scaleX, scaleY)
    for _i=0,#current_input do -- input text 
        lg.print(string.sub(current_input, _i, _i), (8 + (_i * 8))*scaleX, 384*scaleY, 0, scaleX, scaleY)
    end

    cursor_pos_x = #current_input
    if draw_cursor_line then  -- underline 
        lg.line(((cursor_pos_x * 8) + 16)*scaleX, scaleY*399, ((cursor_pos_x * 8) + 24)*scaleX, scaleY*399)
    end

end

local IS_SHIFT = false

function love.keypressed(key, scancode, isrepeat)
    if #scancode == 1 then 
        if IS_SHIFT then 
            scancode = scancode:upper()
            if scancode == '1' then scancode = '!'
            elseif scancode=='2'then scancode='\"'
            elseif scancode=='3'then scancode='#'
            elseif scancode=='4'then scancode='$'
            elseif scancode=='5'then scancode='%'
            elseif scancode=='6'then scancode='&'
            elseif scancode=='7'then scancode='\''
            elseif scancode=='8'then scancode='('
            elseif scancode=='9'then scancode=')'
            elseif scancode=='/'then scancode='?'end
        end
        current_input = current_input .. scancode
    end
    if scancode == "rshift" or scancode == "lshift" then 
        IS_SHIFT = true 
    elseif scancode == "space" then 
        current_input = current_input .. " "
    elseif scancode == "return" then 
        parse_input(current_input)
        current_input = ''
    elseif scancode == "backspace" then 
        current_input = string.sub(current_input, 1, #current_input - 1)
    end
    --print(scancode)
end

function love.keyreleased(key, scancode, isrepeat)
    if scancode == "rshift" or scancode == "lshift" then 
        IS_SHIFT = false 
    end
end

function love.resize(w, h)
    intResolutionX = w
    intResolutionY = h 
end

function love.quit()
    if server ~= nil then 
        server:send(json.encode({type="LOGOUT", uid=my_uid}))
        host:service()
        --server:disconnect()
        host:flush()
    end

    return false -- false = do not abort quit()
end
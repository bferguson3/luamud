-- love2d client 
local lg = love.graphics 

local enet = require "enet"
local json = require "json"
dofile("packets.lua")
dofile("ansi.lua")
dofile("uid.lua")
dofile("c_character.lua")
local bit = require "bit"

local host = enet.host_create()
local server = host:connect("localhost:6789")

USERNAME = "test"
PASSWORD = "test"
local last_ping = 0
local delay = 0
local my_uid = make_UID()

local active_character = nil 
local text_canvas = nil 

-- SCREEN mud_print STUFF
local TEXT_SPD = 2
local current_line = 0
local MAX_CHAR_WIDTH = 80
local MAX_CHAR_HEIGHT = 24
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


local local_enemies = { 
	
}



function mud_print(txt)
    
    for i=1,#txt do
        local _c = string.sub(txt, i, i)
        table.insert(text_buffer, { c = _c, x = current_col, y = current_line, r = {1.0, 1, 0.5}} )
        current_col = current_col + 1
    end
    
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
local p = mud_print

--


function parse_input(f)
	f = string.lower(f)

	-- ATTACK COMMAND 
	if string.find(f, "att") == 1 then 
		p("ATTACKING")
		tgt = ""
		for k,v in pairs(local_enemies) do 
			for token in string.gmatch(f, "[^%s]+") do 
				if tonumber(token) then 
					tgt = local_enemies[tonumber(token)]
				else
					if #token < 3 then 
						p("Attack who?")
						return 
					end
					if string.find(string.lower(v.name), token) then 
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
			p(tgt.name)
		else
			p("No target!")
		end

	-- LOOK COMMAND 
	elseif string.find(f, "loo") == 1 or f == "l" then 
		-- TODO PACKET FROM SERVER 
		p("Looking around, you see:")
		--for k,v in pairs(local_enemies) do 
		--	p(k .. " " .. v.name)
		--end
        server:send(json.encode(CommandPacket:new({uid=my_uid, cmd="LOOK"})))
	end
end

--

function process_packet(e)
	-- e = event object 
	local pak = json.decode(e.data)
	if pak.type == "CHARACTER_DAT" then 
		p("new character data received")
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
	end
end


function love.load()

    font = lg.newFont(8)

    text_canvas = lg.newCanvas(640, 400)

    math.randomseed(os.clock())

    for i=1,(80*25) do -- insert screen as blank 
        table.insert(text_screen, { '', {1, 1, 1} } )
    end

end

function love.update(dt)
        local e = nil 

        txt_blink_ctr = txt_blink_ctr + dt

        -- CHECK SERVER 
		e = host:service()
		if e then
			if e.type == "connect" then -- We connected, first event
				p("Connected: " .. e.peer:connect_id())
				login = LoginPacket:new({uid=my_uid, login=USERNAME, pass=PASSWORD})
				e.peer:send(json.encode(login))
			elseif e.type == "receive" then -- Standard msg event 
				process_packet(e)
			end
		end
		
        -- process text buffer 
        for _i=1,TEXT_SPD do
            if #text_buffer > 0 then 
                text_screen[(text_buffer[1].y * 80) + text_buffer[1].x] = { text_buffer[1].c, text_buffer[1].r }
                table.remove(text_buffer, 1)
            end
        end

        -- draw text screen to canvas during main loop 
        lg.setCanvas(text_canvas)
            lg.clear(0.1, 0.1, 0.1)
            for y=0,24 do
                for x=0,80 do 
                    if(text_screen[(y*80)+x] ~= nil) then 
                        lg.print(text_screen[(y*80)+x], x * 8, y * 16)
                    end
                end
            end
        lg.setCanvas()

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
    
    lg.draw(text_canvas) -- screen

    lg.setColor(1, 1, 1)
    lg.line(0, 400-16, 640, 400-16) -- input rule 

    lg.print("> ", 0, 400-16)
    for _i=0,#current_input do -- input text 
        lg.print(string.sub(current_input, _i, _i), 8 + (_i * 8), 384)
    end

    cursor_pos_x = #current_input
    if draw_cursor_line then  -- underline 
        lg.line((cursor_pos_x * 8) + 16, 399, (cursor_pos_x * 8) + 24, 399)
    end

end

local IS_SHIFT = false

function love.keypressed(key, scancode, isrepeat)
    if #scancode == 1 then 
        if IS_SHIFT then 
            scancode = scancode:upper()
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

function love.quit()
    server:send(json.encode({type="LOGOUT", uid=my_uid}))
    host:service()
    --server:disconnect()
    host:flush()

    return false -- false = do not abort quit()
end
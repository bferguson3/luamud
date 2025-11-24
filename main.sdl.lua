-- love2d sdl client 
local lg = love.graphics 
love.errorhandler = function(s)
    print("\nAn error has occurred and the application will now close:\n"..s.."\n")
end -- print and quit only 
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
dofile("src/feat.lua")
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
    font = lg.newFont(8)

    text_canvas = lg.newCanvas(640, 400)

    math.randomseed(os.time())

    for i=1,(80*25) do -- insert screen as blank 
        table.insert(text_screen, { '', 'fff' } )
    end

end

local function set_lg_color_from_screen(s)
    local r, g, b 
    r = s:sub(1,1)
    g = s:sub(2,2)
    b = s:sub(3,3)
    r = tonumber(r,16)/15
    g = tonumber(g,16)/15
    b = tonumber(b,16)/15
    love.graphics.setColor(r, g, b, 1.0)
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
        e = host:service(1)
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
            p("%rf77Welcome to SworldMud!")
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
    --if(update_canvas)then
    lg.setCanvas(text_canvas)
        lg.clear(0.1, 0.1, 0.1)
        for y=1,24 do
            for x=1,80 do 
                if(screen[(y*80)+x] ~= nil) then 
                    set_lg_color_from_screen(screen[(y*80)+x][2])
                    --lg.setColor(screen[(y*80)+x][2])
                    lg.print(screen[(y*80)+x][1], (x-1) * 8, (y-1) * 16)
                end
            end
        end
    lg.setCanvas()
    --update_canvas = false 
    --end
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
        host:service(1)
        --server:disconnect()
        host:flush()
    end

    return false -- false = do not abort quit()
end
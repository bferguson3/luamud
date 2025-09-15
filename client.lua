
require "enet"
local json = require "json"
dofile("packets.lua")
dofile("ansi.lua")
dofile("uid.lua")
dofile("c_character.lua")

local host = enet.host_create()
local server = host:connect("localhost:6789")

-- Determine OS type for tty settings
local os_type = package.config:sub(1,1) == "\\" and "Windows" or "Unix-like"
if(os_type == "Unix-like")then
	os.execute("stty -icanon min 0 time 1 -echo")
end

USERNAME = "test"
PASSWORD = "test"

-- seed 
math.randomseed(os.clock())

local active_character = nil 

function process_packet(e)
	-- e = event object 
	local pak = json.decode(e.data)
	--print("MSG: ", e.data, e.peer)
	if pak.type == "CHARACTER_DAT" then 
		print("new character data received")
		active_character = Character:new({})
		active_character.from_blob(pak.character)
		print(active_character.name)
		print("DEX", active_character.dex)
		print("AGI", active_character.agi)
		print("STR", active_character.str)
		print("VIT", active_character.vit)
		print("INT", active_character.int)
		print("SPI", active_character.spi)
		print("")
		io.write("> ")
	end
end

local local_enemies = { 
	{ name = "Goblin" },
	{ name = "Goblin Shaman" }
}

Enemy={}
function Enemy:new(o)

end

function parse_input(f)
	f = string.lower(f)

	-- ATTACK COMMAND 
	if string.find(f, "att") == 1 then 
		print("ATTACKING")
		tgt = ""
		for k,v in pairs(local_enemies) do 
			for token in string.gmatch(f, "[^%s]+") do 
				if tonumber(token) then 
					tgt = local_enemies[tonumber(token)]
				else
					if #token < 3 then 
						print("Attack who?")
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
			print(tgt.name)
		else
			print("No target!")
		end

	-- LOOK COMMAND 
	elseif string.find(f, "loo") == 1 or f == "l\n" then 
		-- TODO PACKET FROM SERVER 
		print("Looking around, you see:")
		for k,v in pairs(local_enemies) do 
			print(k, v.name)
		end
	end
end



local my_uid = make_UID()

-- check_server coroutine
local delay = 0
local last_ping = 0.0
local cur_input = ""
local multi_key = false
local last_keycode = 0
local check_server = coroutine.create(function()
	while 1 do
		local e = nil -- declare 
		-- INPUT GRABBING
		-- get delay from last input: 1/10s per char 
		delay = delay + (os.clock() - last_ping) + 0.1
		if delay < 0.2 then 
			inchr = io.read(1)
			if inchr ~= nil then 
				if multi_key then 
					if last_keycode == 27 then 
						if string.byte(inchr) == 91 then 
							last_keycode = 91 
						end 
					elseif last_keycode == 91 then 
						if string.byte(inchr) == 65 then 
							multi_key = false 
							last_keycode = 65
						end
					end	
				end
				if not multi_key then 
					io.write(inchr)
					io.flush()
					cur_input = cur_input .. inchr
				end
				-- 10 = Return -- 27>91>65, 66, 67, 68 = arrows
				--print(string.byte(inchr))
				if string.byte(inchr) == 10 then -- Submit, trim newline from print
					io.write("\x1b[25;1H")
					print("Command: " .. string.sub(cur_input, 1, string.len(cur_input) - 1))
					parse_input(cur_input)
					-- reset input: 
					io.write("> ")
					io.flush()
					cur_input = ""
				elseif string.byte(inchr) == 127 then -- Backspace 
					cur_input = string.sub(cur_input, 1, string.len(cur_input) - 2) 
					io.write("\r")
					io.write("                                                                \r")
					io.write("> " .. cur_input)
				elseif string.byte(inchr) == 27 then 
					multi_key = true 
					last_keycode = 27
				end
			end
			delay = delay + (os.clock() - last_ping) + 0.1
			goto _skip
		end

		-- CHECK SERVER COROUTINE
		e = host:service(1) -- Always 1/10s
		if e then
			if e.type == "connect" then -- We connected, first event
				print("Connected: ", e.peer)
				login = LoginPacket:new({uid=my_uid, login=USERNAME, pass=PASSWORD})
				e.peer:send(json.encode(login))
			elseif e.type == "receive" then -- Standard msg event 
				process_packet(e)
			end
		end
		last_ping = os.clock()
		delay = 0
		
		::_skip::
		coroutine.yield()
	end
end
)
--

local done = false
while not done do -- Main loop 
	-- Check if there's an event:
	coroutine.resume(check_server)
end

server:disconnect()
host:flush()

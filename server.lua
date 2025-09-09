require "enet" 
local json = require "json"
dofile("packets.lua")
dofile("ansi.lua")
dofile("c_client.lua")
dofile("c_character.lua")
dofile("roll.lua")

character_db = {}
active_clients = {}

math.randomseed(os.clock())

-- test:
newchar = Character:new({skill = 9, a = 6, b = 4})

function process_login(p)
	print("Login request from UID " .. p.uid .. " (" .. p.login, p.pass, ")")
	if p.login == "test" and p.pass == "test" then 
		return true 
	end 
	return false 
end

-- Start server:
print("Opening LUAMUD server on 6789...")
local host = enet.host_create("localhost:6789")
print("OK.")
while 1 do

	local e = host:service(10) -- 1/100s update cycle
	
	if e and e.type == "receive" then -- receive event: 
		-- decode event data to json 
		local pak = json.decode(e.data)
		print("GET: ", pak.type, e.peer) -- log it 

		if pak.type == "LOGIN" then  -- is it a LOGIN request?
			if process_login(pak) then  -- if true, pass OK 
				--e.peer:send("LOGIN OK ")
				table.insert(active_clients, Client:new( { uid=pak.uid, login=pak.login } ))
				-- perform SQL query here to pull characters into character_db 
				-- TODO FIXME
				-- for now make a new random 
				_new = Character:new( { user=pak.login, body=7, mind=7, skill=7, a=roll(2), b=roll(2), c=roll(2), d=roll(2), e=roll(2), f=roll(2), name="Test" } )
				e.peer:send(json.encode(_new.to_blob()))
			end
		end
	end
end

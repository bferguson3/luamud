require "enet" 
local json = require "json"
dofile("packets.lua")
dofile("ansi.lua")
ELEMENTS = { 
	None = 0,
	Physical = 1,
	Fire = 2, 
	Magic = 3, 
	Wind = 4,
	Earth = 5,
	Energy = 6,
	Slashing = 7,
	Silver = 8,
	Ice = 9,
	Bludgeon = 10,
	Lightning = 11
}
ITEMTYPE = { 
	Recovery = 1,
	Treasure = 2,
	Equipment = 3
}
ALCHEMY_COLORS = { 
	White = 1,
	Gold = 2,
	Black = 3,
	Red = 4
}
RANK = { 
	C = 1,
	B = 2,
	A = 3,
	S = 4
}

Item={}
function Item:new(o)
    local o = o or {}
    setmetatable(o, self)
    self.__index = self 
    -- 
	o.name = o.name or "ItemName"
	o.type = o.type or ITEMTYPE.Treasure
	o.desc = o.desc or "A piece of treasure for selling."
	o.worth = o.worth or 10 -- in g 
	o.alchemy_color = o.alchemy_color or { ALCHEMY_COLORS.White }
	o.alchemy_rank = o.alchemy_rank or RANK.C
	return o 
end
local Treasure_DB = {}
Treasure_DB.Beautiful_Feathers = Item.new( {name="Beautiful Feathers", worth=30, alchemy_color={ALCHEMY_COLORS.Gold, ALCHEMY_COLORS.Red}, alchemy_rank=RANK.B} )
Treasure_DB.Big_Horn = Item.new( {name="Big Horn", worth=100, alchemy_color={ALCHEMY_COLORS.Red}, alchemy_rank=RANK.B} )
LootTable={}
function LootTable:new(o)
    local o = o or {}
    setmetatable(o, self)
    self.__index = self 
    -- 
	o.treasure = o.treasure or { 
		[0] =  -- 0 = always 
			nil,--Treasure_DB.Beautiful_Feathers,
		[4] = nil, -- 2-4
			-- Nothing
		[10] = -- 5-10
			nil,--Treasure_DB.Big_Horn,
		[12] =  -- 11+
			Item.new({name="Bag of Silver", worth=10*roll()})
	}
	return o 
end
dofile("c_client.lua")
dofile("c_character.lua")
dofile("roll.lua")
dofile("monster.lua")

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

local second_timer = os.clock()
local second_timer_2 = os.clock()
local SEED_TIMER = 30
local PRUNE_TIMER = 60*10
local login_count = 0


--results = { 0, 0, 0, 0, 0, 0 }
--for i=1,100000000 do -- 100mil rolls
--	_r = roll(1, 6)
--	results[_r] = results[_r] + 1
--end
--for k=1,6 do 
--	print(results[k])
--end

while 1 do
	-- Timer stuff 
	if os.clock() > (second_timer + SEED_TIMER) then 
		math.randomseed(os.clock())
		second_timer = os.clock()
		--print("Seeded")
	end
	if os.clock() > (second_timer_2 + PRUNE_TIMER) then 
		for k,v in pairs(active_clients) do 
			print(k,v)
			if (os.clock() - active_clients[k].last_active) > PRUNE_TIMER then 
				active_clients[k] = nil 
				print("disconnected user " .. k)
			end
		end
		second_timer_2 = os.clock()
	end

	-- get any queued packets 
	local e = host:service() 
	if e then
		if e.type == "receive" then -- receive event: 
			-- decode event data to json 
			local pak = json.decode(e.data)
			print("GET: ", pak.type, e.peer) -- log it 

			if pak.type == "LOGIN" then  -- is it a LOGIN request?
				if process_login(pak) then  -- if true, pass OK 
					--e.peer:send("LOGIN OK ")
					--table.insert(active_clients, Client:new( { uid=pak.uid, login=pak.login, last_active=os.clock() } ))
					active_clients[pak.uid] = Client:new( { login=pak.login, last_active=os.clock() })
					login_count = login_count + 1
					print("Current est no. of users: " .. login_count)
					
					-- perform SQL query here to pull characters into character_db ?
					-- TODO FIXME
					-- for now make a new random 
					_new = Character:new( { user=pak.login, body=7, mind=7, skill=7, a=roll(2), b=roll(2), c=roll(2), d=roll(2), e=roll(2), f=roll(2), name="Test" } )
					e.peer:send(json.encode(_new.to_blob()))
				else 
					print("Login failed for user ", e.peer)
				end
			elseif pak.type == "COMMAND" then 
				if active_clients[pak.uid] then 
					-- We are logged in, cmd execute OK 
					print("user " .. active_clients[pak.uid].login .. " used command " .. pak.cmd)
					if pak.cmd == "LOOK" then 
						
					end
				else 
					print("error: user " .. pak.uid .. " not logged in, but tried command " .. pak.cmd)
				end
			elseif pak.type == "LOGOUT" then 
				active_clients[pak.uid] = nil -- std hashmap erase 
				login_count = login_count - 1
			end
		elseif e.type == "disconnect" then 
			--
		else
			print("Unhandled packet type: " .. e.type)
		end
	end
end


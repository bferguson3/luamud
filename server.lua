require "enet" 
local json = require "json"
local sqlite = require 'sqlite.db'
local sha = require("sha2")
dofile("arr.lua")
dofile("sleep.lua")
dofile("enums.lua")
dofile("packets.lua")
dofile("ansi.lua")
dofile("c_client.lua")
dofile("c_character.lua")
dofile("location.lua")
dofile("striketable.lua")
dofile("roll.lua")
dofile("c_statuseffect.lua")

-- LOAD DATABASE KEY 
local MY_DB_KEY = nil
local dbkf = io.open("database_key", "rb")
if dbkf then 
	MY_DB_KEY = dbkf:read("*all")
	dbkf:close()
end
if MY_DB_KEY == nil then 
	print("database_key not found. quitting")
	quit()
end

-- VERYFIY MONSTER DB 
dofile("monster.lua")
ct = 0
for k,v in pairs(Monster_DB)do 
	ct = ct + 1
end
print(ct .. " monsters loaded.")

-- VERIFY ITEM DB 
dofile("item.lua")
ct = 0
for k,v in pairs(Treasure_DB)do 
	ct = ct + 1
end
print(ct .. " treasures loaded.")

local db = nil 
character_db = {}
active_clients = {}

math.randomseed(os.clock())

GAME_MAP={}
-- test loc 
dofile("scenario.lua")

local second_timer = os.clock()
local second_timer_2 = os.clock()
local last_queue_time = os.clock()
local SEED_TIMER = 300
local PRUNE_TIMER = 600
local EVT_QUEUE_LEN = 5
local event_queue={}
local login_count = 0
local next_queue = 1
local second_timer_3 = os.clock()
local CHAR_SAVE_TIMER = 30

ACTIONS = { 
	STD_ATTACK = 1
}
-- EVENT QUEUE TYPES: 
-- "PROCESS COMBAT ROUND"
-- -- src, tgt, action, type 

function get_mod(n)
	n = n - (n % 6) -- cut off remainder 
	n = n / 6
	return math.floor(n)
end

dofile("combat.lua")

-- Start server:
print("Opening LUAMUD server on 6789...")
local host = enet.host_create("*:6789")
print("OK.")

function process_login(p)
	print("Login request from UID " .. p.uid .. " (user " .. p.login ..")")
	local _penc = sha.blake3(p.pass, MY_DB_KEY)
	-- select from users db 
	db = sqlite:open("db/users.db")
	-- TODO: db errors 
	local result = db:select("user_database", {where={user=p.login}} )
	if result[1]==nil then 
		-- If the login entry is not in the database, then add it as new 
		db:execute("INSERT INTO user_database (user, password) VALUES ('" .. p.login .. "', '" .. _penc .. "');")
		db:close()
		print("New user created.")
		return true 
	else 
		-- login exists, comapre. 
		print("User found. Checking password...")
		if result[1].password == _penc then 
			db:close()
			return true 
		else 
			db:close()
			return false 
		end
	end 
	return false 
end

function send_to_room(_ri, _s)
	for i=1,#GAME_MAP[_ri].current_players do 
		print(active_clients[GAME_MAP[_ri].current_players[i]].peer)
		active_clients[GAME_MAP[_ri].current_players[i]].peer:send(json.encode(MessagePacket:new({msg=_s})))
	end
end

function process_event_queues()
	local _elapsed = os.clock() - last_queue_time
	if(_elapsed < 0.1)then 
		sleep(0.1-_elapsed) 
		second_timer = second_timer + 0.1 - _elapsed
		--print(second_timer, second_timer_2, second_timer_3)
		second_timer_2 = second_timer_2 + 0.1 - _elapsed
		second_timer_3 = second_timer_3 + 0.1 - _elapsed
	end
	_elapsed = 0.1
	local to_dl = {}
	for i=1,#event_queue do 
		if event_queue[i] ~= nil then 
			event_queue[i].timer = event_queue[i].timer - _elapsed 
			local evt = event_queue[i]
			if event_queue[i].timer <= 0 then 
				if evt.type == "combat_round" then 
					-- COMBAT EVENT 
					-- 
					if(active_clients[evt.src])then
						-- perform event 
						
						-- src, tgt, action 
						local _char = active_clients[evt.src].current_character
						local _enm = GAME_MAP[_char.location].active_mobs[evt.tgt]
						if(evt.action == ACTIONS.STD_ATTACK)then 
						-- NORMAL ATTACK EVT 
						-- 
							-- resolve 
							print("attack of " .. evt.src .. " vs " .. _enm.name)
							process_attack(_char, _enm, evt.src)

							-- Death resolve part 2: 
							if _enm.cur_hp <= 0 then 
								-- broadcast to entire room 
								send_to_room(_char.location, _enm.name .. " %rfaaperished%rfff!!")
								
								active_clients[evt.src].peer:send(json.encode(MessagePacket:new({msg="You gained %rcc2" .. (MOB_XP[_enm.lv]+_enm.hp) .. " experience."})))
								active_clients[evt.src].current_character.experience = active_clients[evt.src].current_character.experience + MOB_XP[_enm.lv]+_enm.hp
								active_clients[evt.src].current_character.state = STATE.NONE
								GAME_MAP[_char.location].active_mobs[evt.tgt].dead = true -- kill em 
								-- TODO: do this right 
								table.insert(to_dl, i)
								-- TODO: custom respawn timers 
								-- src = index of enemy that died, tgt = location to spawn 
								table.insert(event_queue, { type="respawn", src=evt.tgt, tgt=_char.location, action=nil, timer=60 })
							end
							-- re-initiative: 
							event_queue[i].timer = 7 - (_char.agi/6) -- 7 seconds minus agi/6 (we dont use mod here for granularity)
							if event_queue[i].timer < 1 then event_queue[i].timer = 1 end 
						end
						
					else 
						-- the client must have logged out 
						-- TODO: do this right 
						table.insert(to_dl, i)
					end
				elseif evt.type == "respawn" then 
				--RESPAWN EVENT 
				-- 
					refresh_mob(GAME_MAP[evt.tgt].active_mobs[evt.src]) 
					send_to_room(evt.tgt, GAME_MAP[evt.tgt].mobs[evt.src].name .. " appears.")
					table.insert(to_dl, i)
				end
			end
		end -- ~= nil 
	end
	for i=1,#to_dl do 
		arr_remove_i(event_queue, to_dl[i])
	end
	last_queue_time = os.clock()

	process_status_effects()
end

function process_status_effects()
	-- 0.1s each time 
	for i=1,#GAME_MAP do 
		for j=1,#GAME_MAP[i].active_mobs do 
			local rl = {} -- to delete
			for s=1,#GAME_MAP[i].active_mobs[j].status_mods do -- for every monster that exists, check if it has statuses
				local se = GAME_MAP[i].active_mobs[j].status_mods[s]
				if se[2]>=0 then  -- not an infinite status 
					se[2] = se[2] - 0.1 -- if so, decrement them by the event timer value  
					if se[2] <= 0 then 
						table.insert(rl, s) -- add index to to_delete array 
					end 
				end
					-- otherwise, its still acive, and may have a loop 
				if se[3] >= 0 then -- if [3]>-1 its a repeating event 
					se[3]=se[3]-0.1 -- decrement it too 
					if se[3]<=0 then -- and execute if needed
						se[3]=se[1].looptimer -- reset timer 
						se[1].on_loop(GAME_MAP[i].active_mobs[j]) -- execute onloop event 
					end
				end
			end
			for b=1,#rl do -- delete dead status effects !
				arr_remove_i(GAME_MAP[i].active_mobs[j].status_mods, rl[b])
			end
		end
	end
	-- gotta do these for players too 
end

--
-- MAIN SERVER LOOP
--
while 1 do
	-- Timer stuff 
	-- Reseed the math seed every n seconds
	if second_timer > SEED_TIMER then 
		math.randomseed(os.clock())
		second_timer = 0
		print("math.random reseeded.")
	end
	-- Prune clients that have not done anything
	if second_timer_2 > PRUNE_TIMER then 
		for k,v in pairs(active_clients) do 
			--print(k,v)
			if (os.clock() - active_clients[k].last_active) > PRUNE_TIMER then 
				active_clients[k] = nil 
				print("disconnected user " .. k)
			end
		end
		second_timer_2 = 0
	end
	-- save any clients that are currently online every 10s
	if second_timer_3 > CHAR_SAVE_TIMER then 
		-- for each char logged in, 
		db = sqlite:open("db/characters.db")
		for k,v in pairs(active_clients) do 
			-- INSERT OR REPLACE in the db 
			db:execute(create_char_sqlstr(v.current_character))
		end
		db:close()
		if login_count > 0 then 
			print(login_count .." characters saved to DB.")
		end
		second_timer_3 = 0
	end

	-- Main "events" loop for combat timings etc 
	process_event_queues()


	-- get any queued packets 
	local e = host:service() 
	if e then
		if e.type == "receive" then -- receive event: 
			-- decode event data to json 
			local pak = json.decode(e.data)
			print("GET: ", pak.type, e.peer) -- log it 

			if pak.type == "LOGIN" then  -- is it a LOGIN request?
			-- LOGIN PACKET TYPE 
			-- 
				if process_login(pak) then  -- if true, pass OK 
					active_clients[pak.uid] = Client:new( { login=pak.login, last_active=os.clock(), peer=e.peer })
					login_count = login_count + 1
					print("Current est no. of users: " .. login_count)
					-- -- TODO FIXME perform SQL query here to pull characters into character_db 
					db = sqlite:open("db/characters.db")
					local result = db:select("character_database", { where = { user = pak.login }})
					if result[1] ~= nil then 
						print("Character found: " .. result[1].name .. "(total: " .. #result .. ")")
						-- make new char object and copy in sql result 
						local _tc = Character:new( { user=pak.login  })
						_tc.from_sql(result[1])
						--db:execute("DELETE FROM character_database WHERE user = '" .. pak.login .. "';")
						--db:execute(create_char_sqlstr(_tc))
						active_clients[pak.uid].current_character = _tc -- assign to client object 
						table.insert(GAME_MAP[_tc.location].current_players, pak.uid)
						e.peer:send(json.encode(MessagePacket:new({msg="Welcome back!\nYour primary character has been loaded."})))
						e.peer:send(json.encode(_tc.to_blob()))
						e.peer:send(json.encode(GAME_MAP[_tc.location].make_packet()))
					else 
						-- for now make a new random 
						_new = Character:new( { user=pak.login, body=7, mind=7, skill=7, a=tot(roll(2)), b=tot(roll(2)), c=tot(roll(2)), d=tot(roll(2)), e=tot(roll(2)), f=tot(roll(2)), name="Temp"..math.random(1000) } )
						active_clients[pak.uid].current_character=_new -- this will preserve the reference? 
						table.insert(GAME_MAP[1].current_players, pak.uid) -- add player to the map room start
						e.peer:send(json.encode(MessagePacket:new({msg="Welcome!\nA new character has been created for you."})))
						e.peer:send(json.encode(_new.to_blob()))
						e.peer:send(json.encode(GAME_MAP[_new.location].make_packet())) -- and send the player the room dat
					end
					db:close()
				else 
					print("Login failed for user ", e.peer)
				end

			elseif pak.type == "COMMAND" then 
			-- COMMAND PACKET TYPE 
			-- 
				if active_clients[pak.uid] then -- We are logged in, cmd execute OK 
					if active_clients[pak.uid].peer ~= e.peer then 
						-- WARNING: A user other than the prescribed tried a command. Boot them with no text.
						print("Warning:",e.peer," not validated. Booting them.")
						e.peer:disconnect_now()
						return
					end

					active_clients[pak.uid].last_active = os.clock() -- update time 
					local _char = active_clients[pak.uid].current_character 
					print("user " , active_clients[pak.uid].peer , " used command " .. pak.cmd)

					if pak.cmd == "LOOK" then 
					-- LOOK COMMAND 
						-- take "loc" and use it as the index 
						e.peer:send(json.encode(GAME_MAP[pak.loc].make_packet()))

					elseif pak.cmd == "ATTACK" then 
					-- ATTACK COMMAND 
						-- loc is game map index -- tgt is enemy index 
						if(_char.state ~= STATE.IN_COMBAT)then
							if GAME_MAP[pak.loc].active_mobs[pak.tgt].dead then 
								e.peer:send(json.encode(MessagePacket:new({msg="That enemy has already perished!"})))
							else 
								print(_char.name .. " engages " .. GAME_MAP[pak.loc].active_mobs[pak.tgt].name .. "!")
								_char.state = STATE.IN_COMBAT
								table.insert(event_queue, { type="combat_round", src=pak.uid, tgt=pak.tgt, action=ACTIONS.STD_ATTACK, timer=1 } )
							end
						else 
							-- TODO : change target if needed?
						end

					elseif pak.cmd == "SAY" then
						-- TODO fix this  
						send_to_room(1, active_clients[pak.uid].current_character.name .. " says, \"" .. pak.txt .. "\"")

					elseif pak.cmd == "USE" then 
						-- first check if decoy is on 
						print(pak.txt)
						if string.find(pak.txt,"Decoy Attack")==1 then 
							-- first make sure the featexists 
							local found = false 
							for k=1,#active_clients[pak.uid].current_character.feats do 
								if active_clients[pak.uid].current_character.feats[k] == FEATS.DecoyAttackI then 
									found = true 
								elseif active_clients[pak.uid].current_character.feats[k] == FEATS.DecoyAttackII then 
									found = true 
								end 
							end 
							if not found then 
								e.peer:send(json.encode(MessagePacket:new({msg="You do not know Decoy Attack."})))
							else 
								found = false 
								for ii=1,#active_clients[pak.uid].current_character.status_mods do 
									if string.find(active_clients[pak.uid].current_character.status_mods[ii][1].name,"Decoy Attack")==1 then 
										arr_remove_i(active_clients[pak.uid].current_character.status_mods, ii)-- if so, remove it 
										e.peer:send(json.encode(MessagePacket:new({msg="You stop using Decoy Attack."})))
										found = true 
									end
								end
								-- if not on, enable it 
								if not found then 
									if pak.txt == "Decoy Attack I" then 
										table.insert(active_clients[pak.uid].current_character.status_mods, { Using_DecoyAttackI, -1, -1 })
										e.peer:send(json.encode(MessagePacket:new({msg="You are now using Decoy Attack I."})))
									elseif pak.txt == "Decoy Attack II" then 
										table.insert(active_clients[pak.uid].current_character.status_mods, { Using_DecoyAttackII, -1, -1 })
										e.peer:send(json.encode(MessagePacket:new({msg="You are now using Decoy Attack II."})))
									end
								end
							end
						end
					else 
					-- ??? 
						for k,v in pairs(pak) do 
							print(k,v)
						end

					end
				else 
					print("error: user " .. pak.uid .. " not logged in, but tried command " .. pak.cmd)
				end

			elseif pak.type == "LOGOUT" then 
			-- LOGOUT PACKET TYPE 
			-- 
				-- pop uid from game map 
				if(active_clients[pak.uid])then
					local _t = GAME_MAP[active_clients[pak.uid].current_character.location].current_players
					for i=1,#_t do 
						if _t[i] == pak.uid then 
							table.remove(_t, i)
							break 
						end
					end
					active_clients[pak.uid] = nil -- std hashmap erase 
					login_count = login_count - 1
				end
			end

		elseif e.type == "disconnect" then 
			--
			
		else
			print("Unhandled packet type: " .. e.type)

		end
	end
end

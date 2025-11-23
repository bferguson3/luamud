require "enet" 
local json = require "json"
local sqlite = require 'sqlite'
local sha = require("sha2")
dofile("src/arr.lua")
dofile("src/sleep.lua")
dofile("src/enums.lua")
dofile("src/packets.lua")
dofile("src/ansi.lua")
dofile("src/c_client.lua")
dofile("src/c_character.lua")
dofile("src/location.lua")
dofile("src/striketable.lua")
dofile("src/roll.lua")
dofile("src/c_statuseffect.lua")

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
dofile("src/monster.lua")
ct = 0
for k,v in pairs(Monster_DB)do 
	ct = ct + 1
end
print(ct .. " monsters loaded (of 674 expected).")

-- VERIFY ITEM DB 
dofile("src/item.lua")
ct = 0
for k,v in pairs(Treasure_DB)do 
	ct = ct + 1
end
print(ct .. " treasures loaded.")

local db = nil 
character_db = {}
active_clients = {}

math.randomseed(os.time())

GAME_MAP={}
-- test loc 
dofile("scenario.lua")

local second_timer = os.time()
local second_timer_2 = os.time()
local last_queue_time = os.time()
local SEED_TIMER = 300
local PRUNE_TIMER = 600
local LOGOUT_LIMIT_TMR = 60
local EVT_QUEUE_LEN = 5
event_queue={}
local login_count = 0
local next_queue = 1
local second_timer_3 = os.time()
local CHAR_SAVE_TIMER = 30

ACTIONS = { 
	STD_ATTACK = 1,
	MOB_ATTACK = 2
}
-- EVENT QUEUE TYPES: 
-- "PROCESS COMBAT ROUND"
-- -- src, tgt, action, type 

function get_mod(n)
	n = n - (n % 6) -- cut off remainder 
	n = n / 6
	return math.floor(n)
end

dofile("src/combat.lua")

dofile("src/sw.lua")

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
	local _elapsed = os.time() - last_queue_time
	if(_elapsed < 0.1)then 
		sleep(0.1 - _elapsed) 
		second_timer = second_timer + 0.1 - _elapsed
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
					if(evt.action == ACTIONS.STD_ATTACK)then 
					-- NORMAL ATTACK EVT 
						if(active_clients[evt.src] == nil) then 
							table.insert(to_dl, i)
							print("Removed " .. evt.src .. "from active users...")
						else 
							local _char = active_clients[evt.src].current_character
							local _enm = GAME_MAP[_char.location].active_mobs[evt.tgt]	
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
								-- TODO: do this right < idk what this means
								table.insert(to_dl, i)
								-- TODO: custom respawn timers 
								-- src = index of enemy that died, tgt = location to spawn 
								table.insert(event_queue, { type="respawn", src=evt.tgt, tgt=_char.location, action=nil, timer=60 })
							else -- Now: the enemy has to attack back!
								local _mob = GAME_MAP[_char.location].active_mobs[evt.tgt]
								-- does it already have a target? 
								if(_mob.current_tgt == nil)then
								-- if not, give it: 
									_mob.current_tgt = evt.src --active_clients[evt.src].current_character
								else -- if so, TODO check their Hate scores
									_ = 0 -- 
								end
								--start_fighting(_mob)
								if not _mob.in_combat then 
									_mob.in_combat = true 
									table.insert(event_queue, { type="combat_round", src=_mob, tgt=_mob.current_tgt, action=ACTIONS.MOB_ATTACK, timer=1 } )
								end
								-- debug: 
								--print("event queue: ", #event_queue)
								--for i=1,#event_queue do
								--	print(event_queue[i].type .. " " .. event_queue[i].action)
								--end
							end
							-- re-initiative: 
							event_queue[i].timer = 7 - (_char.agi/6) -- 7 seconds minus agi/6 (we dont use mod here for granularity)
							if event_queue[i].timer < 1 then event_queue[i].timer = 1 end 
						end
					--
					elseif evt.action == ACTIONS.MOB_ATTACK then 
					-- Monsters turn 
						-- is the monster dead? 
						if evt.src.cur_hp <= 0 then 
							evt.src.in_combat = false 
							evt.src.current_tgt = nil 
							table.insert(to_dl, i)
						else
							if not active_clients[evt.tgt] then 
								table.insert(to_dl, i)
								evt.src.in_combat = false
								evt.src.current_tgt = nil 
							else
								-- src : &Monster(), tgt : active_clients[i]
								local _tgt = active_clients[evt.tgt].current_character
								print("attack of " .. evt.src.name .. " vs " .. evt.tgt .. " " .. _tgt.name)
								process_nme_attack(evt.src, _tgt, evt.tgt)
								if _tgt.cur_hp <= 0 then 
									-- process more death if we need to. 
								else 
									-- player is still alive, anything else? 
									if _tgt.state ~= STATE.IN_COMBAT then 
										print(_tgt.name .. " engages " .. evt.src.name .. "!") -- attack back if you arent 
										_tgt.state = STATE.IN_COMBAT
										table.insert(event_queue, { type="combat_round", src=evt.tgt, tgt=evt.src.id, action=ACTIONS.STD_ATTACK, timer=1 } )
									end
								end
								event_queue[i].timer = 7 - (evt.src.initiative/6) 
								if event_queue[i].timer < 1 then event_queue[i].timer = 1 end 
							end
						end
					else 
						print(evt.action) -- debug 
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
	last_queue_time = os.time()

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

function logout_user(uid)
	if(active_clients[uid])then
		active_clients[uid].peer:send(json.encode(MessagePacket:new({msg="You have been disconnected."})))
		local _t = GAME_MAP[active_clients[uid].current_character.location].current_players
		for i=1,#_t do 
			if _t[i] == uid then 
				table.remove(_t, i)
				break 
			end
		end
		active_clients[uid] = nil -- std hashmap erase 
		login_count = login_count - 1
	end
end
--
-- MAIN SERVER LOOP
--
while 1 do
	-- Timer stuff 
	-- Reseed the math seed every n seconds
	if second_timer > SEED_TIMER then 
		math.randomseed(os.time())
		second_timer = 0
		print("math.random reseeded.")
	end
	-- Prune clients that have not done anything
	if second_timer_2 > PRUNE_TIMER then 
		for k,v in pairs(active_clients) do 
			--print(k,v)
			if (os.time() - active_clients[k].last_active) > PRUNE_TIMER then 
				--active_clients[k] = nil 
				logout_user(k)
				print("disconnected user " .. k .. " due to timeout.")
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

	local ignore_login = false 
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
					for k,v in pairs(active_clients) do -- check if someone's login already exists. 
						if active_clients[k].login == pak.login then
							if os.time() - active_clients[k].last_active < LOGOUT_LIMIT_TMR then 
								e.peer:send(json.encode(MessagePacket:new({msg="You need to wait 30 seconds before you are fully logged out.\nPlease type 'quit' or 'exit'..."})))
								ignore_login = true 
							end
							logout_user(k)
							break
						end
					end 
					if not ignore_login then 
						active_clients[pak.uid] = Client:new( { login=pak.login, last_active=os.time(), peer=e.peer })
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
							_tc.derive()
							--db:execute("DELETE FROM character_database WHERE user = '" .. pak.login .. "';")
							--db:execute(create_char_sqlstr(_tc))
							--table.insert(_tc.feats, FEATS.DecoyAttackI)
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
					end
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

					active_clients[pak.uid].last_active = os.time() -- update time 
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
						-- Remove all chars < 0x20 and > 0x7f
						for c=1,#pak.txt do  -- this ignores antyhing 0x80 for some reason. negative? 
							--print(string.byte(string.sub(pak.txt, c, c)))
							if (string.byte(string.sub(pak.txt, c, c)) < 32) or (string.byte(string.sub(pak.txt, c, c)) > 126) then 
								pak.txt = string.sub(pak.txt, 1, c) .. string.sub(pak.txt, c+1, #pak.txt)
							end
						end
						send_to_room(1, active_clients[pak.uid].current_character.name .. " says, \"" .. pak.txt .. "\"")

					elseif pak.cmd == "USE" then 
						print(pak.txt)

						-- first check if decoy is on 
						CheckDecoyAttack(pak, e)
						
						---
					elseif pak.cmd == "HEALME" then 
						active_clients[pak.uid].current_character.cur_hp = active_clients[pak.uid].current_character.hp
						active_clients[pak.uid].current_character.cur_mp = active_clients[pak.uid].current_character.mp
						e.peer:send(json.encode(MessagePacket:new({msg="Okay, you're fully healed."})))

					else 
					-- ??? 
						for k,v in pairs(pak) do 
							print(k,v)
						end

					end
				else 
					print("error: user " .. pak.uid .. " not logged in, but tried command " .. pak.cmd)
					e.peer:send(json.encode(MessagePacket:new({msg="You are currently logged out. Please 'quit' and log back in."})))
				end

			elseif pak.type == "LOGOUT" then 
			-- LOGOUT PACKET TYPE 
			-- 
				print(pak.uid .. " requested logout.")
				-- pop uid from game map 
				if active_clients[pak.uid].current_character.state == STATE.IN_COMBAT then 
					e.peer:send(json.encode(MessagePacket:new({msg="You can't quit in combat!"})))
				else
					logout_user(pak.uid)
				end
				
			end

		elseif e.type == "disconnect" then 
			--
			print("user " .. e.peer:connect_id() .. " disconnected.")
			local _u = nil
			for k,v in pairs(active_clients)do 
				if active_clients[k].peer == e.peer then 
					_u = k 
					break
				end
			end
			if _u ~= nil then 
				logout_user(_u) 
				print("logged out user: " .. _u)
			end 
		else
			print("Unhandled packet type: " .. e.type)

		end
	end
end

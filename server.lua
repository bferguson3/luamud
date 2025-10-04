require "enet" 
local json = require "json"
dofile("enums.lua")
dofile("packets.lua")
dofile("ansi.lua")
dofile("item.lua")
dofile("c_client.lua")
dofile("c_character.lua")
dofile("roll.lua")
dofile("monster.lua")
dofile("location.lua")
dofile("striketable.lua")

character_db = {}
active_clients = {}

math.randomseed(os.clock())

GAME_MAP={}
-- test loc 
dofile("scenario.lua")

-- Start server:
print("Opening LUAMUD server on 6789...")
local host = enet.host_create("*:6789")
print("OK.")

local second_timer = os.clock()
local second_timer_2 = os.clock()
local last_queue_time = os.clock()
local SEED_TIMER = 30
local PRUNE_TIMER = 60*10
local EVT_QUEUE_LEN = 5
local event_queue={}
local login_count = 0
local next_queue = 1

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

function process_login(p)
	print("Login request from UID " .. p.uid .. " (" .. p.login, p.pass, ")")
	if p.login == "test" and p.pass == "test" then 
		return true 
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
	if(_elapsed < 0.1)then os.execute('sleep ' .. 0.1-_elapsed) end
	_elapsed = 0.1
	for i=1,#event_queue do 
		if event_queue[i] ~= nil then 
			event_queue[i].timer = event_queue[i].timer - _elapsed 
			local evt = event_queue[i]
			if event_queue[i].timer <= 0 then 
				if(active_clients[evt.src])then
					-- perform event 
					if evt.type == "combat_round" then 
					-- COMBAT EVENT 
					-- 
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
								
								table.remove(GAME_MAP[_char.location].active_mobs, evt.tgt) -- erase em 
								_enm = nil 
								-- TODO: custom respawn timers 
								table.insert(event_queue, { type="respawn", src=evt.tgt, tgt=_char.location, action=nil, timer=60 })
							end
							-- re-initiative: 
							event_queue[i].timer = 7 - (_char.agi/6) -- 7 seconds minus agi/6 (we dont use mod here for granularity)
							if event_queue[i].timer < 1 then event_queue[i].timer = 1 end 
						end
						-- do not delete until enemy is dead/nil
						if(_enm == nil)then event_queue[i]=nil end 

					end
					-- and delete it if not needed 
					--event_queue[i] = nil 
				else 
					-- the client must have logged out 
					table.remove(event_queue, i)
				end
				if evt.type == "respawn" then 
					--RESPAWN EVENT 
					-- 
					table.insert(GAME_MAP[evt.tgt].active_mobs, GAME_MAP[evt.tgt].mobs[evt.src].copy())
					send_to_room(evt.tgt, GAME_MAP[evt.tgt].mobs[evt.src].name .. " appears.")
					table.remove(event_queue, i)
				end
			end
		end -- ~= nil 
	end
	last_queue_time = os.clock()
end


function add_loot(_char, _item, peer)
	local i = 1
	while i <= 10 do -- do I already have one? CAN THESE BE POINTERS? 
		if(_char.inventory[i][1]==_item)then 
			_char.inventory[i][2] = _char.inventory[i][2] + 1
			peer:send(json.encode(MessagePacket:new({msg="You picked up another %rd4d" .. _item.name .. "%rfff. (Now holding " .. _char.inventory[i][2] .. ")"})))
			return
		end
		i = i+1
	end
	if i == 11 then i = 1 end -- reset if not found 
	while i <= 10 do
		if(_char.inventory[i][2]==0)then 
			break 
		end
		i = i + 1 
	end -- now i is the empty slot, if exists 
	if i < 11 then 
		-- ok, fits 
		_char.inventory[i][1]=_item; _char.inventory[i][2]=1;
		peer:send(json.encode(MessagePacket:new({msg="You found a %rd4d" .. _item.name .. "%rfff on the enemy corpse!"})))
	else -- No room!
		-- TODO: uhh not sure 
		peer:send(json.encode(MessagePacket:new({msg="You found a %rd4d" .. _item.name .. "%rfff, but your inventory is full, so it was left behind..."})))
	end
end

-- combat stuff 
-- Specifically for Player Against Enemy attacks 
function process_attack(_char, _enm, evt)

	local _rl = roll(2, 6, 0)
	local _lvmod = _char.get_level(SKILLS.FIGHTER)
	local _dxmod = get_mod(_char.dex) 
	local _accmod = 0
	local _adddmg = 0
	if(_char.eqp_weapon>0)then
		_accmod = Equipment_DB[_char.eqp_weapon].acc
		_adddmg = Equipment_DB[_char.eqp_weapon].add
	end
	local _t = tot(_rl) + _lvmod + _dxmod + _accmod
	print("Rolled " .. _t .. " (" .. _rl[1] .. ", " .. _rl[2] .. ") + " .. tostring(_lvmod+_dxmod+_accmod))
	if (_rl[1]==1) and (_rl[2]==1) then 
		_t = 0 
		active_clients[evt].peer:send(json.encode(MessagePacket:new({msg="Auto-fail!! %r999(Gained 50 XP.)"})))
		_char.experience = _char.experience + 50 
		return
	end 
	if (tot(_rl)==12)then _t = 999;
		active_clients[evt].peer:send(json.encode(MessagePacket:new({msg="Auto-success!!"})))
	end 
	if _t >= _enm.evade then 
		local _dmg = 0
		local _strike = 0
		local _crit = false 
		local _sr = roll(2, 6, 0)
		_strike = tot(_sr)-2
		if(_char.eqp_weapon>0)then
			-- USING A WEAPON 
			if _strike > 0 then 
				_dmg = strike_table[Equipment_DB[_char.eqp_weapon].power+1][_strike] -- index 
			else _dmg=-1 end
			if((tot(_sr))>=Equipment_DB[_char.eqp_weapon].crit) and (_dmg>0) then _crit=true end 
			if _dmg < 0 then 
				active_clients[evt].peer:send(json.encode(MessagePacket:new({msg="Fumbled! No damage!"})))
			else 
				_dmg = _dmg + get_mod(_char.str) + _adddmg
				local _burst=true
				if _crit then
					while _burst==true do -- Bursting!
						_sr = roll(2,6) -- new strk roll
						if(tot(_sr)>2)then
							_dmg = _dmg + strike_table[Equipment_DB[_char.eqp_weapon].power+1][tot(_sr)-2]
							if(_sr[1]+_sr[2]>=Equipment_DB[_char.eqp_weapon].crit)then _burst=true else _burst=false end 
						else _burst = false end 
					end
				end
				_dmg = _dmg - _enm.def 
				if _dmg < 0 then _dmg = 0 end 
				if(_crit)then
					active_clients[evt].peer:send(json.encode(MessagePacket:new({msg="You %rff0CRITICALLY %rf99strike %rfffthe %r0f2" .. _enm.name .. "%rfff with your %r0fb" .. Equipment_DB[_char.eqp_weapon].name .. " %rffffor %rf88" .. _dmg .. " %rfffdamage!"})))
				else
					active_clients[evt].peer:send(json.encode(MessagePacket:new({msg="You %rf99strike %rfffthe %r0f2" .. _enm.name .. "%rfff with your %r0fb" .. Equipment_DB[_char.eqp_weapon].name .. " %rffffor %rf88" .. _dmg .. " %rfffdamage!"})))
				end
			end
		else
			-- BARE HANDED 
			_dmg = strike_table[1][_strike]
			if(_sr[1]==1)and(_sr[2]==1)then _dmg=-1 end 
			if _dmg < 0 then 
				active_clients[evt].peer:send(json.encode(MessagePacket:new({msg="Fumbled! No damage!"})))
			else
				_dmg = _dmg + get_mod(_char.str)
				_dmg = _dmg - _enm.def 
				if _dmg < 0 then _dmg = 0 end 
				active_clients[evt].peer:send(json.encode(MessagePacket:new({msg="You %rf99strike %rfffthe %r0f2" .. _enm.name .. "%rfff with your fists for %rf88" .. _dmg .. " %rfffdamage!"})))
			end
		end

		-- DEAL DAMAGE TO ENEMY 
		_enm.cur_hp = _enm.cur_hp - _dmg 

		-- PROCESS ENEMY DEATH 
		if(_enm.cur_hp <= 0)then 
			-- give awards 
			if(_enm.loot[1])then 
				-- always trasure 
				print("TODO: Always drop treasure found. need handling!")
			end
			local _lr = tot(roll(2,6))
			for i=_lr,2,-1 do 
				if(_enm.loot[i]~=nil)then 
					print("loot: " .. i .. ":" .. _enm.loot[i].name)
					add_loot(_char, _enm.loot[i], active_clients[evt].peer)
					break
				end
			end
			-- pop is done when we return. ..
		end
	else 
		-- enmy evasion too high ! 
		active_clients[evt].peer:send(json.encode(MessagePacket:new({msg="Missed!!"})))
	end
	
end


--
-- MAIN SERVER LOOP
--
while 1 do
	-- Timer stuff 
	-- Reseed the math seed every n seconds
	if os.clock() > (second_timer + SEED_TIMER) then 
		math.randomseed(os.clock())
		second_timer = os.clock()
	end
	-- Prune clients that have not done anything
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
					-- -- TODO FIXME perform SQL query here to pull characters into character_db ?
					-- for now make a new random 
					_new = Character:new( { user=pak.login, body=7, mind=7, skill=7, a=tot(roll(2)), b=tot(roll(2)), c=tot(roll(2)), d=tot(roll(2)), e=tot(roll(2)), f=tot(roll(2)), name="Temp"..math.random(1000) } )
					_new.location = 1 -- TEMP TEST! ==GAME_MAP[1]
					active_clients[pak.uid].current_character=_new -- this will preserve the reference? 
					table.insert(GAME_MAP[1].current_players, pak.uid) -- add player to the map room start
					e.peer:send(json.encode(_new.to_blob()))
					e.peer:send(json.encode(GAME_MAP[_new.location].make_packet())) -- and send the player the room dat
				else 
					print("Login failed for user ", e.peer)
				end

			elseif pak.type == "COMMAND" then 
			-- COMMAND PACKET TYPE 
			-- 
				if active_clients[pak.uid] then -- We are logged in, cmd execute OK 
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
							print(_char.name .. " engages " .. GAME_MAP[pak.loc].active_mobs[pak.tgt].name .. "!")
							_char.state = STATE.IN_COMBAT
							table.insert(event_queue, { type="combat_round", src=pak.uid, tgt=pak.tgt, action=ACTIONS.STD_ATTACK, timer=1 } )
						else 
							-- TODO : change target if needed?
						end

					elseif pak.cmd == "SAY" then
						-- TODO fix this  
						send_to_room(1, active_clients[pak.uid].current_character.name .. " says, \"" .. pak.txt .. "\"")

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

		elseif e.type == "disconnect" then 
			--
			
		else
			print("Unhandled packet type: " .. e.type)

		end
	end
end

local json = require "json"
function refresh_mob(m)
	m.dead = false
	m.cur_hp = m.hp 
	m.cur_mp = m.mp 
	m.status_mods = {}
end

function add_loot(_char, _item, peer)
	local i = 1
	while i <= 10 do -- do I already have one? CAN THESE BE POINTERS? 
		if(_char.inventory[i][1]==_item)then 
			_char.inventory[i][2] = _char.inventory[i][2] + 1
			peer:send(json.encode(MessagePacket:new({msg="You picked up another %rd4d" .. Treasure_DB[_item].name .. "%rfff. (Now holding " .. _char.inventory[i][2] .. ")"})))
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
		peer:send(json.encode(MessagePacket:new({msg="You found a %rd4d" .. Treasure_DB[_item].name .. "%rfff on the enemy corpse!"})))
	else -- No room!
		-- TODO: uhh not sure 
		peer:send(json.encode(MessagePacket:new({msg="You found a %rd4d" .. Treasure_DB[_item].name .. "%rfff, but your inventory is full, so it was left behind..."})))
	end
end

function damage(_enm, _dmg)
    -- deal damage 
    _enm.cur_hp = _enm.cur_hp - _dmg 
    
    -- check if there is any Decoy Attack x, if so, remove it 
    local r={}
    for i=1,#_enm.status_mods do 
        if _enm.status_mods[i][1].name:find("Decoy Attack")==0 then 
            table.insert(r, i)--_enm.status_mods[i]
        end
    end
    for i=1,#r do 
        arr_remove_i(_enm.status_mods, r[i])
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
    -- get flags for skills 
    local decoy_i = false 
    local decoy_ii = false 
    for i=1,#_char.status_mods do 
        if _char.status_mods[i][1]==Using_DecoyAttackI then 
            decoy_i = true 
            break
        elseif _char.status_mods[i][1]==Using_DecoyAttackII then 
            decoy_ii = true 
            break
        end
    end
    --
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
    -- subtract 2 if decoy 
    if decoy_i or decoy_ii then 
        _t = _t - 2 
    end
	if _t >= _enm.get_evasion() then 
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
        -- add 2 or 8 if decoy atk 
        if decoy_i then _dmg = _dmg + 2 elseif decoy_ii then _dmg = _dmg + 8 end 
		-- DEAL DAMAGE TO ENEMY 
        damage(_enm, _dmg)

		-- PROCESS ENEMY DEATH 
		if(_enm.cur_hp <= 0)then 
			-- give awards 
			if(_enm.loot[1])then 
				-- always trasure 
				print("TODO: Always drop treasure found. need handling!")
			end
			--for k,v in pairs(_enm.loot)do
			--	print(k,v)
			--end
			local _lr = tot(roll(2,6))
			for i=_lr,2,-1 do 
				local lg = false 
				for k,v in pairs(_enm.loot)do 
					if tonumber(k)==i then 
						print("loot: " .. i .. ":" .. Treasure_DB[v].name)
						add_loot(_char,v, active_clients[evt].peer)
						lg = true 
						break	
					end
				end
				if lg then break end 
			end
			-- pop is done when we return. ..
		end
	else
        -- Only apply this if the user has a certain skill active...
        if decoy_i then 
            Effect_DecoyAttackI.on_apply(_enm) 
        elseif decoy_ii then 
            Effect_DecoyAttackII.on_apply(_enm)
        end
        -- enmy evasion too high ! 
        active_clients[evt].peer:send(json.encode(MessagePacket:new({msg="Missed!!"})))
	end
	
end

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
        if _enm.status_mods[i][1].name:find("Decoy Attack")==1 then 
            table.insert(r, i)--_enm.status_mods[i]
        end
    end
    for i=1,#r do 
        arr_remove_i(_enm.status_mods, r[i])
    end
end

-- combat stuff 
function start_fighting(mob)
	--print(mob.name .. " started fighting!")
	-- if the mob isnt already "in combat", set that flag 
	mob.in_combat = true 
	-- and then start an event after 1s 
	print(#event_queue)
	table.insert(event_queue, { type="combat_round", src=mob, tgt=mob.current_tgt, action=ACTIONS.MOB_ATTACK, timer=1 } )
	print(#event_queue)
end

function process_nme_attack(mob, char, tgt)
	-- mob attack is the TARGET rolling evasion vs ur attk 
	local _rl = roll(2, 6, 0)
	-- auto success or fail ? 
	local autoyes = false 
	local autono = false 
	if tot(_rl) == 2 then 
		autono = true 
	elseif tot(_rl) == 12 then 
		autoyes = true
	end
	-- monsters can have Decoy Attack also!
	-- get flags for skills 
    local decoy_i = false 
    --local decoy_ii = false 
    for i=1,#mob.skills do 
        if mob.skills[i]==MOBSKILLS.DecoyAttackI then 
            decoy_i = true 
            break
		end
		-- decoy 2? 
    end

    --
	local _acc = mob.acc 
	if decoy_i then _acc = _acc - 2 end 
	-- further modify _acc for decoyattack: for each stack on the tgt, _acc += 1 or 2.
	for i=1,#char.status_mods do 
		if char.status_mods[i][1] == Effect_DecoyAttackI then 
			_acc = _acc + 1
		end -- again, no evidence we need to code for DecoyAttackII yet 
	end
	
	if autoyes then 
		active_clients[tgt].peer:send(json.encode(MessagePacket:new({msg="Evasion check vs " .. mob.name .. ": Auto-success!"})))
		-- add Decoy Attack debuff to player bc missed 
		if decoy_i then Effect_DecoyAttackI.on_apply(char) end 
		return
	end
	if autono then 
		active_clients[tgt].peer:send(json.encode(MessagePacket:new({msg="Evasion check vs " .. mob.name .. ": Auto-fail!! %r999(Gained 50 XP.)"})))
		char.experience = char.experience + 50 
	end

	-- evasion check is fighter, grappler, fencer + agility 
	local _evlv = 0
	local _mod = 0
	if not autono then -- only care if we didnt fail 
		for i=1,#char.classes do 
			if char.classes[1] == SKILLS.FIGHTER then 
				if char.classes[2] > _evlv then _evlv = char.classes[2] end
			elseif char.classes[1] == SKILLS.FENCER then 
				if char.classes[2] > _evlv then _evlv = char.classes[2] end
			elseif char.classes[1] == SKILLS.GRAPPLER then 
				if char.classes[2] > _evlv then _evlv = char.classes[2] end
			end
		end
		_mod = _evlv + get_mod(char.dex) 
	end
	if (tot(_rl) + _mod) > _acc then -- Dodged!
		active_clients[tgt].peer:send(json.encode(MessagePacket:new({msg=mob.name .. " attacked, but you dodged swiftly!"})))
		if decoy_i then Effect_DecoyAttackI.on_apply(char) end 
		return
	end
	-- autono or failed to dodge 
	local _dmg = tot(roll(mob.dmg[1], mob.dmg[2], mob.dmg[3]))
	if decoy_i then _dmg = _dmg + 2 end -- DecoyAttackI
	-- defense is armor only 
	-- TODO: FOr now, just armor and shield. 
	local _def = 0 
	if char.eqp_armor ~= 0 then 
		_def = _def + Equipment_DB[char.eqp_armor].power 
	end
	if char.eqp_shield ~= 0 then 
		_def = _def + Equipment_DB[char.eqp_shield].power
	end

	_dmg = _dmg - _def 
	if (_dmg < 0) then _dmg = 0 end 
	-- finally, deal dmg.. 
	active_clients[tgt].peer:send(json.encode(MessagePacket:new({msg=mob.name .. " strikes you for " .. tostring(_dmg) .. " damage!"})))
	damage(char, _dmg)

	-- TODO update player packet locally ! 
	
	if char.cur_hp < 0 then 
		-- DEATH 
		active_clients[tgt].peer:send(json.encode(MessagePacket:new({msg="You're dead, but luckily it's not programmed yet."})))
		-- 
	end
end



-- Specifically for Player Against Enemy attacks 
-- MELEE ONLY 
-- NEED TO FIX FOR RANGE AND THROW 
function process_attack(_char, _enm, evt)

	local _rl = roll(2, 6, 0)
	
	local _lvmod = 0
	local _evlv = 0
	for i=1,#_char.classes do 
		if _char.classes[1] == SKILLS.FIGHTER then 
			if _char.classes[2] > _evlv then _evlv = _char.classes[2] end
		elseif _char.classes[1] == SKILLS.FENCER then 
			if _char.classes[2] > _evlv then _evlv = _char.classes[2] end
		elseif _char.classes[1] == SKILLS.GRAPPLER then 
			if _char.classes[2] > _evlv then _evlv = _char.classes[2] end
		end
	end
	_lvmod = _evlv 
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
		active_clients[evt].peer:send(json.encode(MessagePacket:new({msg="Attack: Auto-fail!! %r999(Gained 50 XP.)"})))
		_char.experience = _char.experience + 50 
		return
	end 
	if (tot(_rl)==12)then _t = 999;
		active_clients[evt].peer:send(json.encode(MessagePacket:new({msg="Attack: Auto-success!!"})))
	end 
    -- subtract 2 if decoy 
    if decoy_i or decoy_ii then 
        _t = _t - 2 
    end
	if _t >= _enm.get_evasion() then -- Hit !
		local _dmg = 0
		local _strike = 0
		local _crit = false 
		local _sr = roll(2, 6, 0)
		_strike = tot(_sr)-2 -- this might be -1? is it an index?
		if(_char.eqp_weapon>0)then
			-- USING A WEAPON 
			if _strike > 0 then 
				_dmg = strike_table[Equipment_DB[_char.eqp_weapon].power+1][_strike] -- index 
			else _dmg=-1 end -- fumble 
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
        active_clients[evt].peer:send(json.encode(MessagePacket:new({msg="You missed!!"})))
	end
	
end

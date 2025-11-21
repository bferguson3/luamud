local json = require "json"
-- Sword World explicit stuff
-- Check "use" pak for decoy attack feat 
function CheckDecoyAttack(pak, e)
	if string.find(pak.txt,"Decoy Attack")==1 then 
        --print("DEBUG")
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
				if string.find(active_clients[pak.uid].current_character.status_mods[ii][1].name,"Decoy Attack")~=-1 then 
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
end
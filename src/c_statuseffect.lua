STATUSES = { 
    evade = 1
}
---
StatusEffect={}
function StatusEffect:new(o)
    local o = o or {}
    setmetatable(o, self)
    self.__index = self 
    -- 
    o.name = o.name or "SE"
    o.timer = o.timer or 10 -- in seconds, not rounds 
    o.looptimer = o.looptimer or -1 -- -1 means no loop callback
    o.effects = o.effects or { }
    o.on_apply = function(tgt)
        -- do something to tgt 
    end
    o.on_loop = function(tgt)
    
    end
	return o 
end
----
-- status_mod = { 
--  ref_to_effect=Effect_DecoyAttackI,
--  this_timer=10,
--  loop_timer=-1
-- }

Effect_DecoyAttackI=StatusEffect:new({name="Decoy Attack I", effects={STATUSES.evade, -1}})
Effect_DecoyAttackI.on_apply=function(tgt)
    local _ct = 0 
    for i=1,#tgt.status_mods do 
        if tgt.status_mods[i][1].name == "Decoy Attack I" then 
            _ct = _ct + 1
        end
    end
    if _ct == 4 then return end 
    table.insert(tgt.status_mods, { Effect_DecoyAttackI, 10, -1 } ) -- status_mods={ PtrToEffect, Timer, LoopTimer } ( needs to be copy bc instanced )
end
Using_DecoyAttackI=StatusEffect:new({name="SKILL:Decoy Attack I", timer=-1})

Effect_DecoyAttackII=StatusEffect:new({name="Decoy Attack II", effects={STATUSES.evade, -2}})
Effect_DecoyAttackII.on_apply=function(tgt)
    local _ct = 0 
    for i=1,#tgt.status_mods do 
        if tgt.status_mods[i][1].name == "Decoy Attack II" then 
            _ct = _ct + 1
        end
    end
    if _ct == 4 then return end 
    table.insert(tgt.status_mods, { Effect_DecoyAttackII, 10, -1 } ) -- 
end
Using_DecoyAttackII=StatusEffect:new({name="SKILL:Decoy Attack II", timer=-1})
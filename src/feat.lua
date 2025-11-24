
FEATS = { 
	DecoyAttackI = 1,
	DecoyAttackII = 2
}

Feat={}
function Feat:new(o)
	local o = o or {}
	setmetatable(o, self)
	self.__index = self 
	-- 
	o.desc = o.desc or ""
	return o 
end
Feat_DB={}
Feat_DB[FEATS.DecoyAttackI]=Feat:new({desc="Passive. -2 to accuracy, +2 to damage. Enemy takes -1 (stacks to -4) evade on miss for 10s."})
Feat_DB[FEATS.DecoyAttackII]=Feat:new({desc="Passive. -2 to accuracy, +8 to damage. Enemy takes -2 (stacks to -8) evade on miss for 10s."})

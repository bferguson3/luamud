
Item={}
function Item:new(o)
    local o = o or {}
    setmetatable(o, self)
    self.__index = self 
    -- 
	o.name = o.name or nil
	o.type = o.type or ITEMTYPE.Treasure
	o.desc = o.desc or nil
	o.worth = o.worth or 10 -- in g 
	o.alchemy_color = o.alchemy_color or { ALCHEMY_COLORS.White }
	o.alchemy_rank = o.alchemy_rank or RANK.C

	o.copy = function() 
		local c = {}
		c.name=o.name 
		c.type=o.type 
		c.desc=o.desc 
		c.worth=o.worth 
		c.alchemy_color = o.alchemy_color -- pointer 
		c.alchemy_rank = o.alchemy_rank
		return c
	end
	return o 
end

Equipment={}
function Equipment:new(o)
    local o = o or {}
    setmetatable(o, self)
    self.__index = self 
    -- 
	o.name = o.name or "Knife"
	o.stance = o.stance or STANCES.ONEHAND
	o.acc = o.acc or 0 
	o.rank = o.rank or "B"
	o.power = o.power or 1 
	o.crit = o.crit or 10 
	o.add = o.add or 0 
	o.price = o.price or 30 
	o.other = o.other or ""
	o.desc = o.desc or "A small stabbing instrument."

	o.copy = function()
		local c = {}
		c.name = o.name 
		c.stance = o.stance 
		c.acc = o.acc 
		c.power = o.power 
		c.crit = o.crit 
		c.add = o.add 
		c.price = o.price 
		c.other = o.other 
		c.desc = o.desc  
		c.rank = o.rank 
		return c
	end
	return o 
end

LootTable={}
function LootTable:new(o)
    local o = o or {}
    setmetatable(o, self)
    self.__index = self 
    -- 
	o = o or { 
		nil,  -- 0 = always 
		nil,nil,
		nil, -- 2-4
		nil,nil,nil,nil,nil,	-- Nothing
		nil,--Treasure_DB.Big_Horn,
		nil,
		Item:new({name="Bag of Silver", worth=10*tot(roll())})
	}
	return o 
end

dofile("item_db.lua")
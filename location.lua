
Location={}
function Location:new(o)
	local o = o or {}
	setmetatable(o, self)
	self.__index = self 
	-- 
	o.name = o.name or "[Location]"
	o.shortdesc = o.shortdesc or "This is a location."
	o.desc = o.desc or "This location is certainly a location. There are things and stuff here. A soft breeze touches your cheek."
	o.current_players = o.current_players or {}
	o.mobs = o.mobs or {}
	o.exits = o.exits or { 
		[EXITS.N] = nil,
		[EXITS.S] = nil,
		[EXITS.E] = nil,
		[EXITS.W] = nil,
		[EXITS.U] = nil,
		[EXITS.NE] = nil,
		[EXITS.SE] = nil,
		[EXITS.NW] = nil,
		[EXITS.SW] = nil,
		[EXITS.D] = nil
	}

	o.make_packet = function()
		local p = {}
		p.type="ROOM" -- packet type 

		p.name=o.name
		p.shortdesc=o.shortdesc
		p.desc=o.desc
		p.mobs={}
		p.current_players={}
		for i=1,#o.current_players do 
			p.current_players[i]=o.current_players[i].name
		end
		for i=1,#o.active_mobs do 
			p.mobs[i]=o.active_mobs[i].name -- names only 
		end
		p.exits={}
		for i=1,#o.exits do 
			if o.exits[i] ~= nil then 
				p.exits[i]=1
			else 
				p.exits[i]=0
			end
		end
		return p 
	end

	return o 
end


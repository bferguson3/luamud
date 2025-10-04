Client={} -- class Client
function Client:new(o)
	local o = o or {}
	setmetatable(o, self)
	self.__index = self 
	-- 
	o.uid = o.uid or "INVALID" -- str
	o.login = o.login or "MISSING" -- str 
	o.current_character = o.current_character or nil 
	o.peer = o.peer or nil
	o.last_active = o.last_active or 0 
	-- current_character is a pointer to the entry in character_db 
	return o
end
--
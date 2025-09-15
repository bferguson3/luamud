
LoginPacket={}
function LoginPacket:new(o)
    local o = o or {}
    setmetatable(o, self)
    self.__index = self 
    -- 
    o.type = "LOGIN"
    o.uid = o.uid or "NONE"
    o.login = o.login or "NONE"
    o.pass = o.pass or "NONE"
    return o
end

-- CHARACTER_DAT
-- character = { see c_character.lua }
CommandPacket={}
function CommandPacket:new(o)
    local o = o or {}
    setmetatable(o, self)
    self.__index = self 
    -- 
    o.type = "COMMAND"
    o.uid = o.uid or "NONE" -- we always reference by UID
    o.cmd = o.cmd or "NONE"

    return o
end

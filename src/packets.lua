
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

-- Generic message pkt, can include color?
MessagePacket={}
function MessagePacket:new(o)
    local o = o or {}
    setmetatable(o, self)
    self.__index = self 
    --
    o.type = o.type or "MESSAGE_COMBAT"
    o.msg = o.msg or "%rf82This is color F82"

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
    o.uid = o.uid or nil--"NONE" -- we always reference by UID
    o.cmd = o.cmd or nil--"NONE"
    o.txt = o.txt or nil--"NONE"
    o.loc = o.loc or nil--"NONE"
    o.tgt = o.tgt or nil 

    return o
end

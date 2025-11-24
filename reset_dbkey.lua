local out = {}

math.randomseed(os.time())

for i=1,32 do 
    out[i] = math.random(0,255)
end

local f = io.open("db_key", "wb")
for i=1,32 do 
    f:write(string.char(out[i]))
end

f:close()
package.preload["sha2"] = function()
	local f = io.open("sha2.lua", "r")
	local code 
	if f then 
		local t = f:read("*all")
		f:close()
		code = load(t)
	end
	return code()
end
package.preload['enet'] = function() 
	local path = "./enet.so" 
	local f = assert(package.loadlib(path, "luaopen_enet"))
	f()
end
package.preload['json'] = function() 
	local f = io.open("json.lua", "r")
	local code 
	if f then 
		local t = f:read("*all")
		f:close()
		code = load(t)
	end
	return code()
end

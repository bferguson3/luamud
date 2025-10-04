
local uid_opts={}
--
local i
i = 0x30
while i <= 0x39 do 
	table.insert(uid_opts, i)
	i = i + 1
end 
i = 0x41 
while i <= 0x5a do 
	table.insert(uid_opts, i)
	i = i + 1 
end
i = 0x61
while i <= 0x7a do 
	table.insert(uid_opts, i)
	i = i + 1 
end
--

function make_UID()
	math.randomseed(os.clock())
	local uid = ""
	local _i = 0
	while _i < 16 do 
		local _r = uid_opts[math.random(#uid_opts - 1)]
		uid = uid .. string.char(_r)
		_i = _i + 1
	end
	return uid 
end
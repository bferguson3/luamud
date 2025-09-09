function roll(x, s, n)
	x = x or 1; s = s or 6; n = n or 0 --default 1d6+0
	local _tot = 0
	for _i=1,x do 
		local _d = math.random(s)
		_tot = _tot + _d
	end
	return _tot + n 
end

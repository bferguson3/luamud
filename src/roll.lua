function roll(x, s, n)
	x = x or 1; s = s or 6; n = n or 0 --default 1d6+0
	local _tot = {}
	for _i=1,x do 
		local _d = math.random(s)
		--_tot = _tot + _d
		table.insert(_tot, _d)
	end
	table.insert(_tot, n)
	return _tot 
end

function tot(r)
	local _t = 0
	for i=1,#r do 
		_t = _t + r[i]
	end
	return _t 
end
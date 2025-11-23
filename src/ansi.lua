
ansi_colors = { 
	RED = "31",
	GREEN = "32",
	YELLOW = "33",
	BLUE = "34",
	MAGENTA = "35",
	CYAN = "36",
	WHITE = "37",
	BRWHITE = "97",
	GREY = "90",
	BRRED = "91",
	BRGREEN="92",
	BRYELLOW="93",
	BRBLUE="94",
	BRMAGENTA="95",
	BRCYAN="96"
}

BRK = '\x1b'
CLR = '[0;'
--a = BRK .. CLR .. ansi_colors.RED 

function hide_cursor()
	io.write(BRK .. "[?25l")
end
function show_cursor()
	io.write(BRK .. "[?25h")
end

function color_hex(s)
	if s == 'ff0' then 
		io.write(BRK .. CLR .. ansi_colors.BRYELLOW .. "m")
	elseif s == '00f' then 
		io.write(BRK .. CLR .. ansi_colors.BLUE .. "m")
	elseif s == '77f' then 
		io.write(BRK .. CLR .. ansi_colors.BRBLUE .. "m")
	elseif s == 'f77' then 
		io.write(BRK .. CLR .. ansi_colors.BRRED .. "m")
	elseif s == 'afa' then 
		io.write(BRK .. CLR .. ansi_colors.CYAN .. "m")
	elseif s == 'aaa' then 
		io.write(BRK .. CLR .. ansi_colors.WHITE .. "m")
	elseif s == 'd4d' then 
		io.write(BRK .. CLR .. ansi_colors.MAGENTA .. "m")
	elseif s == 'fff' then 
		io.write(BRK .. CLR .. ansi_colors.BRWHITE .. "m")
	elseif s == '999' then 
		io.write(BRK .. CLR .. ansi_colors.WHITE .. "m")
	elseif s == '0f2' then 
		io.write(BRK .. CLR .. ansi_colors.GREEN .. "m")
	elseif s == '0fb' then 
		io.write(BRK .. CLR .. ansi_colors.CYAN .. "m")
	elseif s == 'f99' then 
		io.write(BRK .. CLR .. ansi_colors.RED .. "m")
	elseif s == 'f88' then 
		io.write(BRK .. CLR .. ansi_colors.RED .. "m")
	end
end
function ansicolor(c)
	if c ~= nil then 
		io.write("\x1b[0;" .. c .. "m")		
	else -- bright white
		io.write("\x1b[0;97m")
	end
end

function color(c)
	if c ~= nil then 
		io.write("\x1b[0;" .. c .. "m")		
	else -- bright white
		io.write("\x1b[0;97m")
	end
end

-- #ff0
-- #AFA 
-- #aaa
-- #D4D 
-- #FFF 
-- #999 
-- #0F2
-- #0FB 
-- #F99 
-- #F88

function topleft()
	io.write("\x1b[H")
end

function moveto(x,y)
	io.write("\x1b[" .. tostring(y) ..";" .. tostring(x) .. "H")
end
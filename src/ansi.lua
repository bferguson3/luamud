
ansi_colors = { 
	RED = "31",
	GREEN = "32",
	YELLOW = "33",
	BLUE = "34",
	MAGENTA = "35",
	CYAN = "36",
	WHITE = "37",
	BRWHITE = "97"
}

BRK = '\x1b'
CLR = '[0;'
--a = BRK .. CLR .. ansi_colors.RED 

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
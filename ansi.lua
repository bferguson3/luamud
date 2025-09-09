
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

function color(c)
	if c ~= nil then 
		io.write("\x1b[0;" .. c .. "m")		
	else -- bright white
		io.write("\x1b[0;97m")
	end
end


local json = require "json"

STATE = { -- ONLY USE THIS FOR COMBAT FLAG !!!! 
	NONE = 0,
	IN_COMBAT = 1
}

FEATS = { 
	DecoyAttackI = 1,
	DecoyAttackII = 2
}

function get_class_string(en)
	if en == SKILLS.CONJURER then return "Conjurer"
	elseif en == SKILLS.FENDER then return "Fencer" 
	elseif en == SKILLS.FIGHTER then return "Fighter"
	elseif en == SKILLS.GRAPPLER then return "Grappler"
	elseif en == SKILLS.MAGITECH then return "Magitech"
	elseif en == SKILLS.PRIEST then return "Priest"
	elseif en == SKILLS.RANGER then return "Ranger"
	elseif en == SKILLS.SAGE then return "Sage"
	elseif en == SKILLS.SCOUT then return "Scout"
	elseif en == SKILLS.SHOOTER then return "Shooter"
	elseif en == SKILLS.SORCERER then return "Sorcerer"
	end
end

Feat={}
function Feat:new(o)
	local o = o or {}
	setmetatable(o, self)
	self.__index = self 
	-- 
	o.desc = o.desc or ""
	return o 
end
Feat_DB={}
Feat_DB[FEATS.DecoyAttackI]=Feat:new({desc="Passive. -2 to accuracy, +2 to damage. Enemy takes -1 (stacks to -4) evade on miss for 10s."})
Feat_DB[FEATS.DecoyAttackII]=Feat:new({desc="Passive. -2 to accuracy, +8 to damage. Enemy takes -2 (stacks to -8) evade on miss for 10s."})

Character={} -- class Character
-- These are pulled from a SQLiteDB querying by user "owner" 
function Character:new(o)
	local o = o or {}
	setmetatable(o, self)
	self.__index = self 
	-- 
	o.user = o.user or "None"
	o.name = o.name or "None"
	o.alv = o.alv or 0 -- derive this too
	o.classes = o.classes or { { SKILLS.FIGHTER, 1 } } -- normal table
	-- attributes and modifiers are derived from the below:
	o.race = o.race or "Human"
	o.a = o.a or 0
	o.b = o.b or 0
	o.c = o.c or 0
	o.d = o.d or 0
	o.e = o.e or 0
	o.f = o.f or 0
	o.skill = o.skill or 0 
	o.body = o.body or 0 
	o.mind = o.mind or 0 
	o.growth = o.growth or { 0, 0, 0, 0, 0, 0 } -- table with 6 nums
	o.fortitude = o.fortitude or 0 
	o.willpower = o.willpower or 0 
	
	o.dex = 0;o.agi = 0;o.str = 0; 
	o.vit = 0;o.int = 0;o.spi = 0
	o.derive = function()
		o.dex = o.skill + o.a + o.growth[1] -- base stats 
		o.agi = o.skill + o.b + o.growth[2]
		o.str = o.body  + o.c + o.growth[3]
		o.vit = o.body  + o.d + o.growth[4]
		o.int = o.mind  + o.e + o.growth[5]
		o.spi = o.mind  + o.f + o.growth[6]
		for s,v in ipairs(o.classes) do 			-- adventure level 
			if v[2] > o.alv then o.alv = v[2] end 
		end
		o.hp = o.vit + (o.alv * 3)
		o.mp = o.spi + (o.alv)
		if o.cur_hp == 0 then 
			o.cur_hp = o.hp 
		end
		if o.cur_mp == 0 then 
			o.cur_mp = o.mp 
		end
	end 
	o.derive()
	
	o.spoken_lang = o.spoken_lang or { LANGUAGES.TRADE_COMMON }
	o.written_lang = o.written_lang or { LANGUAGES.TRADE_COMMON } -- table w strs
	o.feats = o.feats or {} -- table of feat enums, ENUM ONLY!

	o.hp = o.hp or 0
	o.cur_hp = o.hp or 0 
	o.mp = o.mp or 0
	o.cur_mp = o.mp or 0
	o.scars = o.scars or 0
	o.gender = o.gender or "" -- string
	o.age = o.age or 15

	o.location = o.location or 1 -- by index!

	o.state = o.state or STATE.NONE

	-- inventory (aka loot) by PTR
	o.inventory = o.inventory or { {0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0}}
	-- eqp always by index 
	o.eqp_bag = o.eqp_bag or { 0,0,0,0,0,0,0,0,0,0 }
	-- BY INDEX!
	o.eqp_weapon = o.eqp_weapon or 1 -- Equipment_DB[1]
	o.eqp_armor = o.eqp_armor or 0 
	o.eqp_shield = o.eqp_shield or 0 
	o.eqp_accessory = o.eqp_accessory or { 0,0,0,0,0,0,0,0,0 }
	o.status_mods = o.status_mods or { }
	o.experience = o.experience or 0 

	o.get_level = function(sk)
		for i=1,#o.classes do
			if o.classes[i][1] == sk then
				return o.classes[i][2]
			end
		end
		return 0
	end	

	o.p_status = function()
		p("Name: " .. o.name .. "     Player: ".. o.user)
		p(" ALV: " .. o.alv .. "     Race: " .. o.race)
		p(" Skill [" .. o.skill .. "]  Body [" .. o.body .. "]  Mind [" .. o.mind .. "]" )
		p(" DEX  " .. o.dex .. " | AGI  " .. o.agi .." | STR  " .. o.str.. " | VIT  " .. o.vit .. " | INT  " .. o.int .. " | SPI  " .. o.spi)
		p(" HP: < %rf77" .. o.cur_hp .. " / " .. o.hp .. "%rfff >     MP: < %r7ff" .. o.cur_mp .. " / " .. o.mp .. "%rfff >")
		p(" Soulscars: " .. o.scars .. "     Gender: " .. o.gender .. "     Age: " .. o.age)
		local _classes = ""
		for i=1,#o.classes do 
			_classes = _classes .. get_class_string(o.classes[i][1]) .. " " .. o.classes[i][2] .. ", "
		end 
		p("Classes: " .. _classes:sub(1, #_classes-2)) 
		local _eqp = "Weapon: "
		if o.eqp_weapon > 0 then 
			_eqp = _eqp .. Equipment_DB[o.eqp_weapon].name .. " [" .. Equipment_DB[o.eqp_weapon].power .. "]"
		else _eqp = _eqp .. "None" end 
		_eqp = _eqp .. "     Armor: "
		if o.eqp_armor > 0 then 
			_eqp = _eqp .. Equipment_DB[o.eqp_armor].name .. " [" .. Equipment_DB[o.eqp_armor].power .. "]"
		else _eqp = _eqp .. "None" end 
		_eqp = _eqp .. "     Shield: "
		if o.eqp_shield > 0 then 
			_eqp = _eqp .. Equipment_DB[o.eqp_shield].name .. " [" .. Equipment_DB[o.eqp_shield].power .. "]"
		else _eqp = _eqp .. "None" end 
		p(_eqp)
		p(" ")
	end

	o.to_blob = function()
		local _me = {}
		_me.name = o.name 
		_me.alv = o.alv 
		_me.classes = o.classes -- should be OK to ref like this 
		_me.skill = o.skill 
		_me.body = o.body 
		_me.mind = o.mind 
		_me.growth = o.growth 
		_me.fortitude = o.fortitude
		_me.willpower = o.willpower
		_me.dex = o.dex
		_me.agi = o.agi 
		_me.spi = o.spi 
		_me.str = o.str 
		_me.vit = o.vit 
		_me.int = o.int 
		_me.spoken_lang = o.spoken_lang
		_me.written_lang = o.written_lang
		_me.feats = o.feats 
		_me.hp = o.hp 
		_me.cur_hp = o.cur_hp
		_me.mp = o.mp 
		_me.cur_mp = o.cur_mp
		_me.scars = o.scars 
		_me.gender = o.gender 
		_me.age = o.age 
		_me.location = o.location
		_me.inventory = {}
		for i=1,10 do 
			if o.inventory[i][1]~=0 then 
				_me.inventory[i] = {Treasure_DB[o.inventory[i][1]].name, o.inventory[i][2]}
			else 
				_me.inventory[i] = { 0, 0 }
			end
		end
		_me.eqp_bag = {}
		for i=1,10 do 
			if o.eqp_bag[i] ~= 0 then 
				_me.eqp_bag[i] = Equipment_DB[o.eqp_bag[i]].name
			else 
				_me.eqp_bag[i] = ""
			end
		end
		_me.eqp_weapon = o.eqp_weapon 
		_me.eqp_armor = o.eqp_armor 
		_me.eqp_shield = o.eqp_shield 
		_me.eqp_accessory = o.eqp_accessory 
		_me.state = o.state 
		_me.experience = o.experience 
		return { character = _me, type="CHARACTER_DAT" } 
	end
	o.from_blob = function(b) -- this is only used on the CLIENT. 
		--for k,v in pairs(b)do
		--	print(k,v)
		--end
		o.name = b.name 
		o.alv = b.alv 
		o.classes = b.classes 
		o.skill = b.skill 
		o.body = b.body 
		o.mind = b.mind 
		o.growth = b.growth 
		o.fortitude = b.fortitude
		o.willpower = b.willpower
		o.dex = b.dex 
		o.agi = b.agi 
		o.str = b.str 
		o.vit = b.vit 
		o.int = b.int 
		o.spi = b.spi 
		o.spoken_lang = b.spoken_lang
		o.written_lang = b.written_lang
		o.feats = {}
		for i=1,#b.feats do 
			--print(b.feats[i])
			table.insert(o.feats, b.feats[i])
		end
		--o.feats = b.feats 
		o.hp = b.hp 
		o.cur_hp = b.cur_hp 
		o.mp = b.mp 
		o.cur_mp = b.cur_mp 
		o.scars = b.scars 
		o.gender = b.gender 
		o.age = b.age 
		o.location = b.location
		o.inventory = {}
		for i=1,10 do 
			o.inventory[i] = { b.inventory[i][1],b.inventory[i][2] }
		end
		o.eqp_bag = {}
		for i=1,10 do 
			o.eqp_bag[i] = b.eqp_bag[i]
		end
		o.eqp_weapon = b.eqp_weapon 
		o.eqp_armor = b.eqp_armor 
		o.eqp_shield = b.eqp_shield 
		o.eqp_accessory = b.eqp_accessory 
		o.state = b.state 
		o.experience = b.experience 
	end
	o.from_sql = function(b) 
		-- b is blob from sql 
		o.body = b.body
		o.mind = b.mind
		o.skill = b.skill
		o.a = b.a
		o.b = b.b
		o.c = b.c
		o.d = b.d
		o.e = b.e
		o.f = b.f
		o.fortitude = b.fortitude
		o.willpower = b.willpower
		o.mp = b.mp
		o.hp = b.hp
		o.cur_mp = b.cur_mp
		o.cur_hp = b.cur_hp
		o.name = b.name 
		o.experience = b.experience
		o.race = b.race 
		o.scars = b.scars
		o.gender = b.gender 
		o.location = b.location
		o.alv = b.alv
		o.age = b.age 
		o.eqp_weapon = EQUIPMENT.Knife
		o.classes={}
		local tc = {}
		for num in b.classes:gmatch("%d+")do 
			table.insert(tc, num)
		end
		i = 1
		while i < #tc do
			table.insert(o.classes, {tonumber(tc[i]), tonumber(tc[i+1])})
			i = i + 2
		end
		o.growth = {}
		for num in b.growth:gmatch("%d+")do 
			table.insert(o.growth, tonumber(num))
		end
		o.spoken_lang = {}
		for num in b.spoken_lang:gmatch("%d+")do 
			table.insert(o.spoken_lang, tonumber(num))
		end
		o.written_lang = {}
		for num in b.written_lang:gmatch("%d+")do 
			table.insert(o.written_lang, tonumber(num))
		end
		o.feats = {}
		for num in b.feats:gmatch("%d+")do 
			table.insert(o.feats, tonumber(num))
		end
		o.inventory={}
		tc = {}
		for num in b.inventory:gmatch("%d+")do 
			table.insert(tc, num)
		end
		i = 1
		while i < #tc do
			table.insert(o.inventory, {tonumber(tc[i]), tonumber(tc[i+1])})
			i = i + 2
		end
		o.eqp_bag={}
		for num in b.eqp_bag:gmatch("%d+")do 
			table.insert(o.eqp_bag, tonumber(num))
		end
		o.derive()
		-- todo 
-- eqp_armor	0
-- eqp_shield	0
-- eqp_accessory	[0,0,0,0,0,0,0,0,0]
	end
	return o 
end

function validate_sql_input(s)
	for i=1,s:len() do 
		local _c = string.byte(s:sub(i, i))
		if (_c<48) or ((_c>57)and(_c<65)) or ((_c>90)and(_c<97)) or (_c>122) then 
			return false 
		end
	end
	return true 
end

function create_char_sqlstr(o)
	-- first verify input: name, user, gender
	--o.name = "; insert into "
	if o.name:len() > 16 then 
		print("INVALID INPUT: name (too long)")
		return
	end
	if(not validate_sql_input(o.name))then
		print("INVALID INPUT: name")
		return
	end
	if(not validate_sql_input(o.user))then
		print("INVALID INPUT: user")
		return
	end
	if(not validate_sql_input(o.gender))then
		print("INVALID INPUT: gender")
		return
	end
	
	local _s = "INSERT OR REPLACE INTO character_database (name, user, alv, classes, race, a, b, c, d, e, f, skill, body, mind, growth, fortitude, willpower, spoken_lang, written_lang, \
feats, hp, cur_hp, mp, cur_mp, scars, gender, age, location, inventory, eqp_bag, eqp_weapon, eqp_armor, eqp_shield, \
eqp_accessory, experience)\
VALUES (\
'" .. o.name .. "',\
'" .. o.user .. "',\
" .. o.alv .. ",\
'["--[[1,1]]
    for i=1,#o.classes do
        _s = _s .. '[' .. o.classes[i][1] .. ',' .. o.classes[i][2] .. '],'
    end 
    _s = string.sub(_s, 1, #_s-1) -- cut last , 
    _s = _s .. "]',\n"
    _s = _s .. "'" .. o.race .. "',\
" .. o.a .. ",\
" .. o.b .. ",\
" .. o.c .. ",\
" .. o.d .. ",\
" .. o.e .. ",\
" .. o.f .. ",\
" .. o.skill .. ",\
" .. o.body .. ",\
" .. o.mind .. ",\
'["
    for i=1,#o.growth do 
        _s = _s .. o.growth[i] .. ','
    end
    _s = _s:sub(1, #_s-1)
    _s = _s .. "]',\
".. o.fortitude .. ",\
".. o.willpower .. ",\
'["
    for i=1,#o.spoken_lang do 
        _s = _s .. o.spoken_lang[i] .. ','
    end
    _s = _s:sub(1, #_s-1)
    _s = _s .. "]',\
'["
    for i=1,#o.written_lang do 
        _s = _s .. o.written_lang[i] .. ','
    end
    _s = _s:sub(1, #_s-1)
    _s = _s .. "]',\
'["
    for i=1,#o.feats do 
        _s = _s .. o.feats[i] .. ','
    end
	_s = _s:sub(1, #_s-1)
    _s = _s .. "]',\
" .. o.hp .. ",\
" .. o.cur_hp .. ",\
" .. o.mp .. ",\
" .. o.cur_mp .. ",\
" .. o.scars .. ",\
'" .. o.gender .. "',\
" .. o.age .. ",\
" .. o.location .. ",\
'["
    for i=1,#o.inventory do
        _s = _s .. '[' .. o.inventory[i][1] .. ',' .. o.inventory[i][2] .. '],'
    end 
    _s = string.sub(_s, 1, #_s-1) -- cut last , 
    _s = _s .. "]',\
'["
    for i=1,#o.eqp_bag do 
        _s = _s .. o.eqp_bag[i] .. ','
    end
    _s = string.sub(_s, 1, #_s-1) -- cut last , 
    _s = _s .. "]',\
" .. o.eqp_weapon .. ",\
" .. o.eqp_armor .. ",\
" .. o.eqp_shield .. ",\
'["
    for i=1,#o.eqp_accessory do 
        _s = _s .. o.eqp_accessory[i] .. ','
    end
    _s = _s:sub(1, #_s-1)
    _s = _s .. "]',\
" .. o.experience .. ")"
	
	return _s 
end
--
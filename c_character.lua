SKILLS = { -- skill_entry = { FIGHTER, 1 }
	FIGHTER 	= 1,
	GRAPPLER 	= 2,
	FENCER 		= 3,
	SHOOTER 	= 4,
	SORCERER 	= 5,
	CONJURER 	= 6,
	MAGITECH 	= 7,
	PRIEST 		= 8,
	RANGER 		= 9,
	SCOUT 		= 10,
	SAGE 		= 11
}

LANGUAGES = { 
	TRADE_COMMON = 1, 
	BARBARIC = 2,
	OGRE = 3,
	DRAKISH = 4,
	ARCANA = 5, 
	SYLVAN = 6, 
	YOUMA = 7,
	LIZARDMAN = 8
}

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
	o.skills = o.skills or { { SKILLS.FIGHTER, 1 } } -- normal table
	-- attributes and modifiers are derived from the below:
	o.race = o.race or "None"
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
		for s,v in ipairs(o.skills) do 			-- adventure level 
			if v[2] > o.alv then o.alv = v[2] end 
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

	o.to_blob = function()
		local _me = {}
		_me.name = o.name 
		_me.alv = o.alv 
		_me.skills = o.skills 
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
		return { character = _me, type="CHARACTER_DAT" } 
	end
	o.from_blob = function(b)
		o.name = b.name 
		o.alv = b.alv 
		o.skills = b.skills 
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
		o.feats = b.feats 
		o.hp = b.hp 
		o.cur_hp = b.cur_hp 
		o.mp = b.mp 
		o.cur_mp = b.cur_mp 
		o.scars = b.scars 
		o.gender = b.gender 
		o.age = b.age 
	end
	return o 
end
--
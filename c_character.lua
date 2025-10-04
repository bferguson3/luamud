local json = require "json"

STATE = { 
	NONE = 0,
	IN_COMBAT = 1
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
	o.classes = o.classes or { { SKILLS.FIGHTER, 1 } } -- normal table
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
		for s,v in ipairs(o.classes) do 			-- adventure level 
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

	o.location = o.location or 0 -- by index!

	o.state = o.state or STATE.NONE

	-- inventory (aka loot) by PTR
	o.inventory = o.inventory or { {0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0}}
	-- eqp always by index 
	o.eqp_bag = o.eqp_bag or { {0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0}}
	-- BY INDEX!
	o.eqp_weapon = o.eqp_weapon or 1 -- Equipment_DB[1]
	o.eqp_armor = o.eqp_armor or 0 
	o.eqp_shield = o.eqp_shield or 0 
	o.eqp_accessory = o.eqp_accessory or { 0,0,0,0,0,0,0,0,0 }

	o.experience = o.experience or 0 

	o.get_level = function(sk)
		for i=1,#o.classes do
			if o.classes[i][1] == sk then
				return o.classes[i][2]
			end
		end
		return 0
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
				_me.inventory[i] = {o.inventory[i][1].name, o.inventory[i][2]}
			else 
				_me.inventory[i] = { 0, 0 }
			end
		end
		_me.eqp_bag = {}
		for i=1,10 do 
			if o.eqp_bag[i][1] ~= 0 then 
				_me.eqp_bag[i] = { o.eqp_bag[i][1].name, o.eqp_bag[i][2] }
			else 
				_me.eqp_bag[i] = { 0, 0}
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
		o.feats = b.feats 
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
			o.eqp_bag[i] = { b.eqp_bag[i][1],b.eqp_bag[i][2] }
		end
		o.eqp_weapon = b.eqp_weapon 
		o.eqp_armor = b.eqp_armor 
		o.eqp_shield = b.eqp_shield 
		o.eqp_accessory = b.eqp_accessory 
		o.state = b.state 
		o.experience = b.experience 
	end
	return o 
end
--
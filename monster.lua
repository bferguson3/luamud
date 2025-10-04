MOB_XP={
83, -- 12
90, -- 11 
107, -- 14
115, -- 13
133, -- 15
156, -- 16 
176, -- 17
222, -- 18 
263, -- 19 
300, -- 20 
357, -- 21
409, -- 22
456, -- 23
500, -- 24
540 -- 25
} -- 270 kills to max lv in 1 classs

-- mob xp = (req xp tnl)/(20+[5*lv])


CHAR_XP_TABLE_MAIN={
	1000, -- 1.0
	1000, -- 1.0
	1500, -- 1.5
	1500, -- 1.5
	2000, -- 2.0
	2500, -- 2.5 
	3000, -- 3.0
	4000, -- 4.0 
	5000, -- 5.0 
	6000, -- 6.0
	7500, -- 7.5
	9000, -- 9.0
	10500, -- 10.5
	12000, -- 12.0
	13500  -- 13.5
}

CHAR_XP_TABLE_SUB={
	500,
	1000,
	1000,
	1500,
	1500,
	2000,
	2500,
	3000,
	4000,
	5000,
	6000,
	7500,
	9000,
	10500,
	12000
}

OLD_MOB_XP={25,
50,
112,
150,
250,
375,
525,
800,
1125,
1500,
2062,
2700,
3412,
4200,
5062}

Monster={}
function Monster:new(o)
    local o = o or {}
    setmetatable(o, self)
    self.__index = self 
    -- 
	o.name = o.name or "NoName"
	o.lv = o.lv or 1
	o.type = o.type or "Barbarous"
	o.int = o.int or INTELLIGENCE.Low
	o.perception = o.perception or PERCEPTION.Normal
	o.soulscars = o.soulscars or 1
	o.language = o.language or { LANGUAGES.TRADE_COMMON }
	o.tgt_rep = o.tgt_rep or 5
	o.tgt_wk = o.tgt_wk or 10
	o.weakness = o.weakness or { ELEMENTS.Physical, 1 } -- +1 phys dmg
	o.initiative = o.initiative or 8
	o.move = o.move or 10 -- unused?
	o.fort = o.fort or 1 -- roll these
	o.will = o.will or 1 
	o.acc = o.acc or 1 -- roll!
	o.dmg = o.dmg or { 2, 6, 0 } -- 2d+0
	o.evade = o.evade or 1 -- roll!
	o.def = o.def or 1 -- dmg mitigation 
	o.hp = o.hp or 10
	o.cur_hp = o.cur_hp or o.hp
	o.mp = o.mp or 5
	o.cur_mp = o.cur_mp or o.mp
	o.skills = o.skills or { }
	o.loot = o.loot or {}
    o.desc = o.desc or "A monster description"

	o.copy = function()
		local c = {}
		c.name=o.name 
		c.lv=o.lv 
		c.type=o.type
		c.int=o.int
		c.perception=o.perception
		c.soulscars=o.soulscars
		c.language={}
		for i=1,#o.language do 
			c.language[i]=o.language[i]
		end
		c.tgt_rep=o.tgt_rep
		c.tgt_wk=o.tgt_wk
		c.weakness={}
		c.weakness[1]=o.weakness[1]
		c.weakness[2]=o.weakness[2]
		c.initiative=o.initiative
		c.move=o.move
		c.fort=o.fort
		c.will=o.will
		c.acc=o.acc
		c.dmg={}
		c.dmg[1]=o.dmg[1]
		c.dmg[2]=o.dmg[2]
		c.dmg[3]=o.dmg[3]
		c.evade=o.evade
		c.def=o.def
		c.hp=o.hp
		c.cur_hp=o.cur_hp
		c.mp=o.mp
		c.cur_mp=o.cur_mp
		c.skills=o.skills -- this table alone is a ptr, should be fine
		c.loot={}
		for i=1,12 do 
			c.loot[i]=o.loot[i]
		end
		c.desc=o.desc
		return c 
	end

    return o
end


Monster_DB = {}
Monster_DB.Goblin = Monster:new( { name="Goblin", 
	perception=PERCEPTION.Darkvision, 
	language={LANGUAGES.BARBARIC},
	weakness={ELEMENTS.Magic, 2},
    lv=2,
	initiative=11, -- spd = (7 - (monster.initiative/6))
	fort=3,
	will=3,
	acc=10,
	dmg={2,6,2},
	evade=10,
	def=2,
	hp=16,
	mp=12,
	loot={nil,nil,
		Treasure_DB[TREASURES.Crude_Weapon],
		nil,nil,nil,nil,nil,
		Treasure_DB[TREASURES.Weapon],
		nil,nil,
		Treasure_DB[TREASURES.HQWeapon]
	},
	desc="A green-skinned, scantily-clad barbarous."
})

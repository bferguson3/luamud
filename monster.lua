
INTELLIGENCE = { 
	Low = 1,
	Average = 2,
	High = 3
}

PERCEPTION = { 
	Normal = 1,
	Darkvision = 2
}

DISPOSITION = { 
	Neutral = 1,
	Hostile = 2
}

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
	o.loot = o.loot or LootTable:new({})
    o.desc = o.desc or "A monster description"
    return o
end


local Monster_DB = {}
Monster_DB.Goblin = Monster.new( { name="Goblin", 
	perception=PERCEPTION.Darkvision, 
	language={LANGUAGES.TRADE_COMMON, LANGUAGES.BARBARIC},
	weakness={ELEMENTS.Magic, 2},
	initiative=11,
	fort=3,
	will=3,
	acc=3,
	dmg={2,6,2},
	evade=3,
	def=2,
	hp=16,
	mp=12,
	loot=LootTable:new({treasure={
		[3]=Item.new({name="Crude Weapon",worth=10,alchemy_color={ALCHEMY_COLORS.Black, ALCHEMY_COLORS.White},alchemy_rank=RANK.B}),
		[9]=Item.new{{name="Weapon",worth=30,alchemy_color={ALCHEMY_COLORS.Black, ALCHEMY_COLORS.White}, alchemy_rank=RANK.B}},
		[12]=Item.new{{name="High-Quality Weapon",worth=150,alchemy_color={ALCHEMY_COLORS.Black, ALCHEMY_COLORS.White}, alchemy_rank=RANK.A}}
	}}),
	desc="A green-skinned, scantily-clad barbarous."
})

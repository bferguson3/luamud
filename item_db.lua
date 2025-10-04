
Equipment_DB = {}
EQUIPMENT = { 
	Knife = 1
}
Equipment_DB[EQUIPMENT.Knife] = Equipment:new({}) -- Knife = 1
Treasure_DB = {}
TREASURES = { 
	Beautiful_Feathers = 1,
	Big_Horn = 2,
	Crude_Weapon = 3, -- goblin
	Weapon = 4,
	HQWeapon = 5
}
Treasure_DB[TREASURES.Beautiful_Feathers] = Item:new( {name="Beautiful Feathers", worth=30, alchemy_color={ALCHEMY_COLORS.Gold, ALCHEMY_COLORS.Red}, alchemy_rank=RANK.B} )
Treasure_DB[TREASURES.Big_Horn] = Item:new( {name="Big Horn", worth=100, alchemy_color={ALCHEMY_COLORS.Red}, alchemy_rank=RANK.B} )
Treasure_DB[TREASURES.Crude_Weapon] = Item:new({name="Crude Weapon",worth=10,alchemy_color={ALCHEMY_COLORS.Black, ALCHEMY_COLORS.White},alchemy_rank=RANK.B})
Treasure_DB[TREASURES.Weapon] = Item:new({name="Weapon",worth=30,alchemy_color={ALCHEMY_COLORS.Black, ALCHEMY_COLORS.White},alchemy_rank=RANK.B})
Treasure_DB[TREASURES.HQWeapon] = Item:new({name="High-Quality Weapon",worth=150,alchemy_color={ALCHEMY_COLORS.Black, ALCHEMY_COLORS.White},alchemy_rank=RANK.A})

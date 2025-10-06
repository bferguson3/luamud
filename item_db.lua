
Equipment_DB = {}
EQUIPMENT = { 
	Knife = 1
}
Equipment_DB[0] = nil 
Equipment_DB[EQUIPMENT.Knife] = Equipment:new({}) -- Knife = 1
--Treasure_DB = {}
--Treasure_DB[TREASURES.BeautifulFeathers] = Item:new( {name="Beautiful Feathers", worth=30, alchemy_color={ALCHEMY_COLORS.Gold, ALCHEMY_COLORS.Red}, alchemy_rank=RANK.B} )
--Treasure_DB[TREASURES.BigHorn] = Item:new( {name="Big Horn", worth=100, alchemy_color={ALCHEMY_COLORS.Red}, alchemy_rank=RANK.B} )
--Treasure_DB[TREASURES.CrudeWeapon] = Item:new({name="Crude Weapon",worth=10,alchemy_color={ALCHEMY_COLORS.Black, ALCHEMY_COLORS.White},alchemy_rank=RANK.B})
--Treasure_DB[TREASURES.Weapon] = Item:new({name="Weapon",worth=30,alchemy_color={ALCHEMY_COLORS.Black, ALCHEMY_COLORS.White},alchemy_rank=RANK.B})
--Treasure_DB[TREASURES.HighqualityWeapon] = Item:new({name="High-Quality Weapon",worth=150,alchemy_color={ALCHEMY_COLORS.Black, ALCHEMY_COLORS.White},alchemy_rank=RANK.A})
dofile("db/treasure_db.lua")
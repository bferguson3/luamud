
Equipment_DB = {}
EQUIPMENT = { 
	Knife = 1,
	ClothArmor = 2
}
Equipment_DB[0] = nil 
Equipment_DB[EQUIPMENT.Knife] = Equipment:new({}) -- Knife = 1
Equipment_DB[EQUIPMENT.ClothArmor] = Equipment:new(
	{
		name = "Cloth Armor",
		evasion = 0,
		min_str = 1, 
		power = 2, 
		price = 15, 
		desc = "Armor made of cloth. Grapplers can equip.",
		elements = { ELEMENTS.NonMetal }
	}
)


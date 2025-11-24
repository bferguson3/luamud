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

EXITS = { 
	N=1,
	S=2,
	E=3,
	W=4,
	NE=5,
	SE=6,
	NW=7,
	SW=8,
	U=9,
	D=10
}

LANGUAGES = { 
	None = 0,
	Barbaric = 1,
	Youma = 2,
	TradeCommon = 3,
	Drakish = 4,
	Arcana = 5,
	Aviary = 6,
	Ogre = 7,
	Gilman = 8,
	Lizardman = 9,
	Centaur = 10,
	Sylvan = 11,
	Dragonic = 12,
	Elven = 13,
	Androscorpion = 14,
	Magitech = 15,
	Merman = 16,
	Daemonic = 17,
	Giantish = 18,
	Minotaur = 19,
	Avian = 20,
	Lycanthrope = 21,
	Basilisk = 22,
	SeaAnimal = 23,
	languagesbymagicsystem = 24,
	Nosferatu = 25,
	RegionalDialect = 26,
	Vargian = 27,
	Lycant = 28,
	Draconic = 29,
	All = 30,
	Various = 31,
	Daemoniclanguagesaddedbyshapeshift = 32,
	Arcane = 33,
	MagicSystemLearned = 34,
	Tradecommon = 35,
	Vulcan = 36,
	Giant = 37,
	LearnedMagicLanguage = 38,
	Formica = 39,
	RegionalDialectDorden = 40,
	RegionaldialectDorden = 41,
	Centaurian = 42,
	Magitechlanguage = 43
}

ELEMENTS = { 
	None = 0,
	Physical = 1,
	Fire = 2, 
	Magic = 3, 
	Wind = 4,
	Earth = 5,
	Energy = 6,
	Slashing = 7,
	Silver = 8,
	Ice = 9, -- or water 
	Bludgeoning = 10,
	Lightning = 11,
	Healing = 12,
	Evasion = 13, -- penalty to dodge
	Melee = 14,
	Ranged = 15,
	NonMetal = 16
}

ITEMTYPE = { 
	Recovery = 1,
	Treasure = 2,
	Equipment = 3
}

ALCHEMY_COLORS = { 
	White = 1,
	Gold = 2,
	Black = 3,
	Red = 4, 
	Green = 5
}

RANK = { 
	B = 1,
	A = 2,
	S = 3,
	SS = 4
}

STANCES = { 
	ONEHAND = 1,
	TWOHAND = 2
}

INTELLIGENCE = { 
	Low = 1,
	Average = 2,
	High = 3,
	Animal = 4,
	None = 5,
	Servant = 6
}

PERCEPTION = { 
	Normal = 1,
	Darkvision = 2
}

DISPOSITION = { 
	Neutral = 1,
	Hostile = 2
}


MOBTYPES = { 
	Barbarous = 1,
	MythicalBeast = 2,
	Fairy = 3,
	Animal = 4,
	Plant = 5,
	Undead = 6,
	Daemon = 7,
	Humanoid = 8,
	Golem = 9,
	Construct = 10,
	Magitech = 11
}


GAMESTATE={
    LOGIN_SCREEN = 1,
    NORMAL_GAME = 2,
    GET_IP = 3,
    GET_USER = 4,
    GET_PASS = 5,
	QUIT = 6
}
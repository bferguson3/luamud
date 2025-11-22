GAME_MAP[1] = Location:new({name="%r00fRaxia Adventurer Guild No.31%rfff",
	shortdesc="A bustling adventurer's guild.",
	desc="This guild is bustling with activity. Aspiring adventurers are coming and going.\
There are a number of tables filled with drinking patrons, and behind a long\
bar on one side of the room is the guild proprieter. He eyes you as you walk\
in with a friendly-ish stare.",
	mobs={ 
		Monster_DB.Goblin,
		Monster_DB.Goblin 
	},
	active_mobs = {
		Monster_DB.Goblin.copy(1),
		Monster_DB.Goblin.copy(2)
	}})

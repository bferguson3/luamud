GAME_MAP[1] = Location:new({
	name="%r77fRaxia Adventurer Guild No.31%rfff",
	shortdesc="A bustling adventurer's guild.",
	desc="This guild is bustling with activity. Aspiring adventurers are coming and going.\
There are a number of tables filled with drinking patrons, and behind a long\
bar on one side of the room is the guild proprieter. He eyes you as you walk\
in with a friendly-ish stare.",
	mobs={ 
		Monster_DB.Goblin,
		Monster_DB.Goblin 
	},
	exits={
		[EXITS.S] = 2
	},
	--search = function(uid)end,-- use default "nothing here" search 
	talk = function(uid)
		table.insert(event_queue,{ type="message", 
			tgt=uid, 
			msg="TALK TO BARTENDER\nThe barkeep waves you over. \"New adventurer, huh? Guess I could give you some\nadvice. Type 'help' to list commands.\"", 
			timer=0 } )
		table.insert(event_queue,{ type="message", 
			tgt=uid, 
			msg=" \nBarkeep \"First thing you gotta do is type 'stats' to view your status.\n Cool, right? Keep an eye on your equipment.\"", 
			timer=3 } )
		table.insert(event_queue,{ type="message", 
			tgt=uid, 
			msg=" \nBarkeep \"When you're ready, head 'south' to the graveyard.\"", 
			timer=6 } )
	end
	}
)

GAME_MAP[2] = Location:new({
	name="%r999Raxia Graveyard%rfff",
	shortdesc = "An abandonded, overgrown graveyard.",
	desc ="A chilling mist hangs in the air. Leafless trees are scattered\
about the barren park, punctuated with the occasional\
odd cracked gravestone. There are a number of open graves...",
	mobs ={
		Monster_DB.ZombieDog
	},
	exits = { [EXITS.N] = 1 }
})
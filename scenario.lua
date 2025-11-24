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
			msg="The barkeep waves you over. \"New adventurer, huh? Guess I could give you some\nadvice.\"", 
			timer=0 } )
		table.insert(event_queue,{ type="message", 
			tgt=uid, 
			msg="Barkeep \"First thing you gotta do is type 'stats' to view your status.\nCool, right?\"", 
			timer=3 } )
		table.insert(event_queue,{ type="message", 
			tgt=uid, 
			msg="Barkeep \"When you're ready, head north to the graveyard.\"", 
			timer=6 } )
		
		
	end
	}
)


import re,json,os,sys


langs=[]
treasures=[]
mobskils=[]

f = open("mobdb.json", "r")
mobdb = f.read()
f.close()
mobdb = json.loads(mobdb)
p = 0
finalstr = ""
while p < len(mobdb["monster_db"]):
	_mob = mobdb["monster_db"][p][0]['monster']
	_outstr = ""
	_outstr+= "Monster_DB."
	#<name wo spaces or special chars>
	_nm = re.sub(r'[^a-zA-Z0-9]','',_mob["monstername"])
	_outstr += _nm + " = Monster:new({\n\
		name=\'" + _mob["monstername"]+ "',\n\
		lv=" + _mob["level"] + ",\n\
		type="
	if(_mob["monstertype"]=="Barbarous"):
		_outstr += "MOBTYPES.Barbarous,\n\
		"
	elif(_mob["monstertype"]=="Mythical Beast"):
		_outstr += "MOBTYPES.MythicalBeast,\n\
		"
	elif(_mob["monstertype"]=="Fairy"):
		_outstr += "MOBTYPES.Fairy,\n\
		"
	elif(_mob["monstertype"]=="Animal"):
		_outstr += "MOBTYPES.Animal,\n\
		"
	elif(_mob["monstertype"]=="Plant"):
		_outstr += "MOBTYPES.Plant,\n\
		"
	elif(_mob["monstertype"]=="Undead"):
		_outstr += "MOBTYPES.Undead,\n\
		"
	elif(_mob["monstertype"]=="Golem"):
		_outstr += "MOBTYPES.Golem,\n\
		"	
	elif(_mob["monstertype"]=="Humanoid"):
		_outstr += "MOBTYPES.Humanoid,\n\
		"
	elif(_mob["monstertype"]=="Daemon"):
		_outstr += "MOBTYPES.Daemon,\n\
		"
	elif(_mob["monstertype"]=="Construct"):
		_outstr += "MOBTYPES.Construct,\n\
		"
	elif(_mob["monstertype"]=="Magitech"):
		_outstr += "MOBTYPES.Magitech,\n\
		"
	else: 
		print("-- ERROR mob " + str(p) + " not barbarous or myth beast " + _mob["monstertype"])
		p += 1
		continue

	_outstr += "int="
	if(_mob["intelligence"]=="Low"):
		_outstr += "INTELLIGENCE.Low,\n\
		"
	elif(_mob["intelligence"]=="Average"):
		_outstr += "INTELLIGENCE.Average,\n\
		"
	elif(_mob["intelligence"]=="High"):
		_outstr += "INTELLIGENCE.High,\n\
		"
	elif(_mob["intelligence"]=="Animal"):
		_outstr += "INTELLIGENCE.Animal,\n\
		"
	elif(_mob["intelligence"]=="None"):
		_outstr += "INTELLIGENCE.None,\n\
		"
	elif(_mob["intelligence"]=="Servant"):
		_outstr += "INTELLIGENCE.Servant,\n\
		"
	else:
		print("-- ERROR no intelligence ?", _mob["intelligence"])
	_outstr += "perception="
	if(_mob["perception"]=="Five senses")or(_mob["perception"]=="Five Senses"):
		_outstr += "PERCEPTION.Normal,\n\
		"
	elif(_mob["perception"]=="Five senses (Darkvision)")or(_mob["perception"]=="Five Senses (Darkvision)"):
		_outstr += "PERCEPTION.Darkvision,\n\
		"
	elif(_mob["perception"]=="Magic"):
		_outstr += "PERCEPTION.Magic,\n\
		"
	elif(_mob["perception"]=="Mechanical"):
		_outstr += "PERCEPTION.Mechanical,\n\
		"
	else:
		print("-- ERROR unsupported perception for mob " + str(p), _mob["perception"])
		p += 1 
		continue 
	_sc = 0
	try:
		_sc = int(_mob["soulscars"])
	except:
		print("-- skipping: odd soulscars...")
		p += 1 
		continue 
	_outstr += "soulscars=" + _mob["soulscars"] + ",\n"
	_outstr += "	language={"
	_langs = _mob["language"].split(", ")
	for l in _langs:
		_outstr += "LANGUAGES." + re.sub(r'[^a-zA-Z0-9]', '', l) + ","
		found = False 
		for mm in langs:
			if mm == re.sub(r'[^a-zA-Z0-9]', '', l):
				found = True 
		if not found:
			langs.append(re.sub(r'[^a-zA-Z0-9]', '', l))
	_outstr = _outstr[:len(_outstr)-1] + "},\n\
		tgt_rep=" + _mob["reputation"] + ",\n"
	if _mob["weakness"] != "-":
	 	_outstr += "tgt_wk=" + _mob["weakness"] + ",\n"
	if _mob["weakpoint"].find("Magic") == 0: 
		_d = re.sub(r'[^0-9]', '', _mob["weakpoint"])
		_outstr += "\tweakness={ ELEMENTS.Magic, " + _d + "},\n\t"
	elif _mob["weakpoint"].find("Bludgeoning") == 0: 
		_d = re.sub(r'[^0-9]', '', _mob["weakpoint"])
		_outstr += "\tweakness={ ELEMENTS.Bludgeoning, " + _d + "},\n\t"
	elif _mob["weakpoint"].find("Physical") == 0: 
		_d = re.sub(r'[^0-9]', '', _mob["weakpoint"])
		_outstr += "\tweakness={ ELEMENTS.Physical, " + _d + "},\n\t"
	elif _mob["weakpoint"].find("Accuracy") == 0: 
		_d = re.sub(r'[^0-9]', '', _mob["weakpoint"])
		_outstr += "\tweakness={ ELEMENTS.Evasion, " + _d + "},\n\t"
	elif _mob["weakpoint"].find("Wind") == 0: 
		_d = re.sub(r'[^0-9]', '', _mob["weakpoint"])
		_outstr += "\tweakness={ ELEMENTS.Wind, " + _d + "},\n\t"
	elif _mob["weakpoint"].find("Earth") == 0: 
		_d = re.sub(r'[^0-9]', '', _mob["weakpoint"])
		_outstr += "\tweakness={ ELEMENTS.Earth, " + _d + "},\n\t"
	elif _mob["weakpoint"].find("Energy") == 0: 
		_d = re.sub(r'[^0-9]', '', _mob["weakpoint"])
		_outstr += "\tweakness={ ELEMENTS.Energy, " + _d + "},\n\t"
	elif _mob["weakpoint"].find("Fire") == 0: 
		_d = re.sub(r'[^0-9]', '', _mob["weakpoint"])
		_outstr += "\tweakness={ ELEMENTS.Fire, " + _d + "},\n\t"
	elif _mob["weakpoint"].find("Slashing") == 0: 
		_d = re.sub(r'[^0-9]', '', _mob["weakpoint"])
		_outstr += "\tweakness={ ELEMENTS.Slashing, " + _d + "},\n\t"
	elif _mob["weakpoint"].find("Water") == 0: 
		_d = re.sub(r'[^0-9]', '', _mob["weakpoint"])
		_outstr += "\tweakness={ ELEMENTS.Ice, " + _d + "},\n\t"
	elif _mob["weakpoint"].find("Silver") == 0: 
		_d = re.sub(r'[^0-9]', '', _mob["weakpoint"])
		_outstr += "\tweakness={ ELEMENTS.Silver, " + _d + "},\n\t"
	elif _mob["weakpoint"].find("Lightning") == 0: 
		_d = re.sub(r'[^0-9]', '', _mob["weakpoint"])
		_outstr += "\tweakness={ ELEMENTS.Lightning, " + _d + "},\n\t"
	elif _mob["weakpoint"].find("HP Recovery") == 0: 
		_d = re.sub(r'[^0-9]', '', _mob["weakpoint"])
		_outstr += "\tweakness={ ELEMENTS.Healing, " + _d + "},\n\t"
	elif _mob["weakpoint"].find("None") == 0: 
		_d = re.sub(r'[^0-9]', '', _mob["weakpoint"])
		_outstr += "\tweakness={ },\n\t"
	else:
		print("-- Non-MAGIC weakness for mob " + str(p) + _mob["weakpoint"])
		p += 1 
		continue 
	# if () exists for init, use the parentheses
	if _mob["initiative"].find("(")!=-1:
		print("-- odd initiative ")
		p += 1
		continue 
	_outstr += "initiative=" + _mob["initiative"] + ",\n\t"
	_mv = _mob["movementspeed"][:2]
	try:
		_mv = int(_mv)
	except:
		_mv = 0
	# fort, will, acc, evade all have () sometimes! (and init)
	_outstr += "move=" + str(_mv) + ",\n\t"
	if _mob["fortitude"].find("(") != -1: 
		_f = re.sub(r'(\(.*\))', '', _mob["fortitude"]) # just truncate these fucking things and add 7 
	else:
		_f = _mob["fortitude"]
	if _f:
		_f = int(_f) + 7
	else:
		_f = 0
	_outstr += "fort=" + str(_f) + ",\n\t"
	if _mob["willpower"].find("(") != -1: 
		_f = re.sub(r'(\(.*\))', '', _mob["willpower"])
	else: 
		_f = _mob["willpower"]
	_f = int(_f) + 7
	_outstr += "will=" + str(_f) + ",\n\t"
	if len(_mob["combatstyles"])==1:
		if _mob["combatstyles"][0]["accuracy"].find("(") != -1: 
			_f = re.sub(r'(\(.*\))', '', _mob["combatstyles"][0]["accuracy"])
		else: 
			_f = _mob["combatstyles"][0]["accuracy"]
		if _f == "-":
			_f = -7
		_f = int(_f)+7
		_outstr += "acc=" + str(_f) + ",\n\t"
		if _mob["combatstyles"][0]["evasion"].find("(") != -1: 
			_f = re.sub(r'(\(.*\))', '', _mob["combatstyles"][0]["evasion"])
		else: 
			_f = _mob["combatstyles"][0]["evasion"]
		_f = int(_f)+7
		_outstr += "evade=" + str(_f) + ",\n\t"
		
		_outstr += "def=" + _mob["combatstyles"][0]["defense"] + ",\n\t"
		_die = _mob["combatstyles"][0]["damage"].split("d")[0]
		if _mob["combatstyles"][0]["damage"].find("+") != -1:
			_add = _mob["combatstyles"][0]["damage"].split("+")[1]
		else:
			_add = "0"
		if _mob["combatstyles"][0]["damage"].find("-") != -1: 
			_add = _mob["combatstyles"][0]["damage"].split("-")[1]
		if _die != "-":
			_outstr += "dmg={" + _die + ",6," + _add + "},\n\t"
		_outstr += "hp=" + _mob["combatstyles"][0]["hp"] + ",\n\t"
		_mp = 0
		if _mob["combatstyles"][0]["mp"] == "-":
			_mp = 0
		else:
			_mp = _mob["combatstyles"][0]["mp"]
		_outstr += "mp=" + str(_mp) + ",\n\t"
	else:
		print("-- MORE THAN 1 COMBAT STYLE, canceling for " + str(p))
		p += 1
		continue
	if(_mob["uniqueskills"]):
		if len(_mob["uniqueskills"][0]["abilities"])>0:
			if(_mob["uniqueskills"][0]["abilities"][0]["title"]!=""):
				_outstr += "skills={"
				for s in _mob["uniqueskills"][0]["abilities"]:
					_n = re.sub(r'(&.*;)', '', s["title"])
					_n = re.sub(r'[^a-zA-Z0-9]','',_n)
					if ord(_n[0]) >= ord('0') and ord(_n[0])<=ord('9'):
						_n = "_" + _n
					_outstr += "MOBSKILLS." + _n +","
					g = 0
					found = False
					while g < len(mobskils):
						if mobskils[g] == _n:
							found = True 
						g += 1
					if not found:
						mobskils.append(_n)
				_outstr = _outstr[:len(_outstr)-1] + "},\n\t"
	if len(_mob["loottable"])>0:
		_outstr += "loot={"
		if _mob["loottable"][0]["roll"]=="Always":
			r = _mob["loottable"][0]
			_n = r["loot"]
			_n = re.sub(r'(\(.*\))', '', _n).rstrip()
			_n_ns = re.sub(r'[^A-Za-z0-9]', '', _n)
			_outstr += "TREASURES." + _n_ns + ", nil,\n\t"
			_desc = re.search(r'(\(.*\))', r["loot"])
			if _desc != None:
				_desc = _desc.group()[:len(_desc.group())-1]
				_desc = _desc[1:]
			t = 0
			found = False
			while t < len(treasures):
				_z = re.sub(r'[^A-Za-z0-9]', '', treasures[t][0])
				if(_z==_n_ns):
					if _desc != None:
						if(treasures[t][1].replace(" ","")==_desc.replace(" ","")):
							found = True	
						else:
							print("-- WARNING: treasure skipped but not same description", treasures[t][1], _desc)
							found = True 
				t += 1
			if not found:
				treasures.append((_n, _desc))
		else: 
			_outstr += "nil, nil,\n\t"
		i = 1
		_ctr = 3
		while i < len(_mob["loottable"]):
			r = _mob["loottable"][i]
			# first get name only, then get alchemic stuff 
			_n = r["loot"]
			_n = re.sub(r'(\(.*\))', '', _n).rstrip()
			_desc = re.search(r'(\(.*\))', r["loot"])
			if _desc != None:
				_desc = _desc.group()[:len(_desc.group())-1]
				_desc = _desc[1:]
				#print(_dl)
			_n_ns = re.sub(r'[^A-Za-z0-9]', '', _n)
			# now figure out highest Roll number 
			_c = 0
			biggest = 0
			while _c < len(r["roll"]):
				try:
					_a = int(r["roll"][_c])
					if _a >  biggest:
						biggest = _a 
				except:
					_c += 1
					continue
				_c += 1
			while _ctr < biggest - 1:
				_outstr += "nil,"
				_ctr += 1
			if(_n_ns != "Nothing")and(_n_ns != "None"):
				# TODO: nab the value and alchemy colors 
				_outstr += "TREASURES." +_n_ns + ",\n\t"
				t = 0
				found = False
				while t < len(treasures):
					_z = re.sub(r'[^A-Za-z0-9]', '', treasures[t][0])
					if(_z==_n_ns):
						if(treasures[t][1].replace(" ", "")==_desc.replace(" ", "")):
							found = True					
						else:
							print("--WARNING: treasure same but diff description", treasures[t][1], _desc)
							found = True 
					t += 1
				if not found:
					treasures.append((_n, _desc))
			else: 
				_outstr += "nil,"
			i += 1
		while _ctr < 11:
			_outstr += "nil,"
			_ctr += 1 
		_outstr = _outstr[:len(_outstr)-1] + "}"
	_outstr += "})\n\n\t"
	finalstr += _outstr
	p += 1
#print(finalstr)
finalstr += "TREASURES = { "
c = 0
while c < len(treasures):
	finalstr += treasures[c][0] + " = " + str(c) + ",\n"
	c += 1
finalstr = finalstr[:len(finalstr)-2]
finalstr += "\n}\n\n"

finalstr += "LANGUAGES = { "
c = 0
while c < len(langs):
	finalstr += langs[c] + " = " + str(c) + ",\n"
	c += 1
finalstr = finalstr[:len(finalstr)-2]
finalstr += "\n}\n\n"

finalstr += "MOBSKILLS = { "
c = 0
while c < len(mobskils):
	finalstr += mobskils[c] + " = " + str(c) + ",\n"
	c += 1
finalstr = finalstr[:len(finalstr)-2]
finalstr += "\n}\n\n"

#print(finalstr)

tstr = "Treasure_DB={}\n"
i = 0
while i < len(treasures):
	_n_ns = re.sub(r'[^A-Za-z0-9]', '', treasures[i][0])
	tstr += "Treasure_DB[TREASURES." + _n_ns + "] = Item:new( {name=\"" + treasures[i][0] + "\", "
	if treasures[i][1] != None:
		_p = re.sub(r'[^0-9]', '', treasures[i][1].split("G")[0])
		if _p != "":
			worth = int(_p)
		else:
			worth = 0
	else:
		worth = 0
	_clrs=[]
	tstr += "worth=" + str(worth) + ", alchemy_color={  "
	if treasures[i][1] != None:
		if(treasures[i][1].find("Red")!=-1):
			tstr += "ALCHEMY_COLORS.Red, "
		elif(treasures[i][1].find("Green")!=-1):
			tstr += "ALCHEMY_COLORS.Green, "
		elif(treasures[i][1].find("Black")!=-1):
			tstr += "ALCHEMY_COLORS.Black, "
		elif(treasures[i][1].find("Gold")!=-1):
			tstr += "ALCHEMY_COLORS.Gold, "
		elif(treasures[i][1].find("White")!=-1):
			tstr += "ALCHEMY_COLORS.White, "
		tstr = tstr[:len(tstr)-2] + "}, alchemy_rank=RANK."
		if(treasures[i][1].find(" B")!=-1):
			tstr += "B})\n"
		elif(treasures[i][1].find(" A")!=-1):
			tstr += "A})\n"
		elif(treasures[i][1].find(" S")!=-1):
			tstr += "S})\n"
		elif(treasures[i][1].find(" SS")!=-1):
			tstr += "SS})\n"
		else: 
			tstr += "B})\n"
	else:
		tstr += "}, alchemy_rank=RANK.B})\n"
	i += 1
	
print(tstr)
-- Delete db/users.db and db/characters.db if they exist!
-- RESET TABLES AFTER DELETE 
--package.path = package.path .. ";"
--package.preload["sqlite"] = function()
--	local path = "libsqlite3.so"
--	local f = assert(package.loadlib(path))
--	f()
--end

local sqlite = require "sqlite"

local db = sqlite:open("db/users.db")
db:execute("CREATE TABLE user_database (\
	user TEXT PRIMARY KEY, \
	password TEXT\
);")
db:close() 

db = sqlite:open("db/characters.db")
db:execute("CREATE TABLE character_database (\
	name TEXT PRIMARY KEY, \
	user TEXT,\
	alv INTEGER,\
	classes TEXT,\
	race TEXT,\
	a INTEGER,\
	b INTEGER,\
	c INTEGER,\
	d INTEGER,\
	e INTEGER,\
	f INTEGER,\
	skill INTEGER,\
	body INTEGER,\
	mind INTEGER,\
	growth TEXT, \
	fortitude INTEGER,\
	willpower INTEGER,\
	spoken_lang TEXT,\
	written_lang TEXT,\
	feats TEXT,\
	hp INTEGER,\
	cur_hp INTEGER,\
	mp INTEGER,\
	cur_mp INTEGER,\
	scars INTEGER,\
	gender TEXT,\
	age INTEGER,\
	location INTEGER,\
	inventory TEXT,\
	eqp_bag TEXT,\
	eqp_weapon INTEGER,\
	eqp_armor INTEGER,\
	eqp_shield INTEGER,\
	eqp_accessory TEXT,\
	experience INTEGER \
);")
db:close()

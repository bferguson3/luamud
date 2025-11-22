package = "swmud"
version = "scm-1"
source = {
   url = "git+https://github.com/bferguson3/luamud.git"
}
description = {
   summary = "1. `$ brew install lua`",
   detailed = "1. `$ brew install lua`",
   homepage = "https://github.com/bferguson3/luamud",
   license = "*** please specify a license ***"
}
dependencies = {
}
build = {
   type = "builtin",
   modules = {
      ansi = "ansi.lua",
      arr = "arr.lua",
      c_character = "c_character.lua",
      c_client = "c_client.lua",
      c_statuseffect = "c_statuseffect.lua",
      client = "client.lua",
      combat = "combat.lua",
      conf = "conf.lua",
      ["db.monster_db"] = "db/monster_db.lua",
      ["db.treasure_db"] = "db/treasure_db.lua",
      enet = {
         incdirs = {
            "../enet/include"
         },
         libdirs = {
            "../enet/build"
         },
         libraries = {
            "enet"
         },
         sources = {
            "../lua-enet/enet.c"
         }
      },
      enums = "enums.lua",
      item = "item.lua",
      item_db = "item_db.lua",
      json = "json.lua",
      location = "location.lua",
      main = "main.lua",
      monster = "monster.lua",
      packets = "packets.lua",
      resetsqldb = "resetsqldb.lua",
      roll = "roll.lua",
      scenario = "scenario.lua",
      server = "server.lua",
      sha2 = "sha2.lua",
      sleep = "sleep.lua",
      striketable = "striketable.lua",
      sw = "sw.lua",
      template = "template.lua",
      uid = "uid.lua"
   }
}

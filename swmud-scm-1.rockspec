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
      ansi = "src/ansi.lua",
      arr = "src/arr.lua",
      c_character = "src/c_character.lua",
      c_client = "src/c_client.lua",
      c_statuseffect = "src/c_statuseffect.lua",
      client = "client.lua",
      combat = "src/combat.lua",
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
      enums = "src/enums.lua",
      item = "src/item.lua",
      item_db = "db/item_db.lua",
      json = "json.lua",
      location = "src/location.lua",
      main = "main.lua",
      monster = "src/monster.lua",
      packets = "src/packets.lua",
      resetsqldb = "resetsqldb.lua",
      roll = "src/roll.lua",
      scenario = "scenario.lua",
      server = "server.lua",
      sha2 = "sha2.lua",
      sleep = "src/sleep.lua",
      striketable = "src/striketable.lua",
      sw = "src/sw.lua",
      template = "template.lua",
      uid = "src/uid.lua"
   }
}

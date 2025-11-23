## OSX build instructions
### Requires luajit, enet, sqlite (luarocks recommended)

1. `$ brew install lua`

2. `$ brew install luarocks`

3. luajit: get source from luajit.org
`$ MACOSX_DEPLOYMENT_TARGET=11.0 make && sudo make install`

4. `$ luarocks install enet --lua-version=5.1`
then `$ cp <build folder>/enet.so ./`

5. `$ luarocks install sqlite --lua-version=5.1`
then `$ cp <build folder>/luv.so ./`


## Run Server
`luajit ./server.lua`


## Run Client
`love ./` for Love2D client

`luajit ./client.lua` tty client

## BUILD/DIST INFO 

.so files needed: 

lua-enet

 `https://leafo.net/lua-enet/`

luasqlite3

 `https://lua.sqlite.org/home/index`


Both may require `<sudo> luarocks install enet/lsqlite3` 

LuaSQLite3 requires 'luarocks install luv'

Native bins for LibUV, Enet, Sqlite may be needed, or installable from pak manager:
 https://github.com/libuv/libuv

 https://github.com/lsalzman/enet

 https://sqlite.org/src/rchvdwnld/release

I had to edit defs.lua to find the sql lib path on Ubuntu:

`sudo nano /usr/local/share/lua/5.1/sqlite/defs.lua`

Fresh install needs: 

 `python3 ./make_database_key.py` 

 `luajit ./resetsqldb.lua` 

 `luajit ./server.lua` 

-

Client:

`luajit ./client.lua `

## client parity 
### client.lua 
ATTACK, LOOK, SAY, USE (decoy attack), HEALME, LOGOUT
### main.sdl.lua (love2D graphical window)
ATTACK, LOOK, SAY, USE (decoy attack) 
### main.lua (love2D console-only)

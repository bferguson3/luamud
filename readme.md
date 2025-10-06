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
`luajit server.lua`


## Run Client
### client.lua no longer works, use love2d 
`love ./`

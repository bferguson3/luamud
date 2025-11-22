./bin/luapak make ../swmud/swmud-scm-1.rockspec \
    --lua-impl="LuaJIT" \
    --lua-incdir="../luajit/src" \
    --lua-lib="../luajit/src/libluajit.so" \
    -s ../swmud/client.lua

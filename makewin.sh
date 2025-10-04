rm dist.zip 
rm ./client/*.lua 
cp ansi.lua ./client/
cp c_character.lua ./client/
cp conf.lua ./client/
cp enums.lua ./client/
cp json.lua ./client/
cp main.lua ./client/
cp item.lua ./client/
cp item_db.lua ./client/
cp packets.lua ./client/
cp uid.lua ./client/
rm ./client/*.love 
cd client 
zip client.love ./*
cd .. 
rm ./dist/*.zip 
cat ../love-11.5-win64/love.exe ./client/client.love > ./dist/luamud.exe
zip dist.zip ./dist/*

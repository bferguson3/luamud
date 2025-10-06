import random 
random.seed()
ob = []
i = 0
while i < 32:
    ob.append(random.randint(0,255))
    i += 1
f = open("database_key", "wb")
f.write(bytes(ob))
f.close()
print("new database_key generated. WARNING: OLD PASSWORDS WILL NOT WORK")
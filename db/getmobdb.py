import urllib.request as url
import json 
import time

reponse = url.urlopen("https://sw25.nerdsunited.com/api/v1/monster/get/1")
reponse = reponse.read().decode("utf-8")
print(reponse)

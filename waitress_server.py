
# serving with waitress took local requests per second from ~200 to ~800


from waitress import serve
import application


import sys
hostStr = ""
appEnv = ""
if(len(sys.argv) > 1 and sys.argv[1] == "local"):
    hostStr = "localhost"
    appEnv = "local"
else:
    hostStr = "0.0.0.0"
    appEnv = "remote"

# serve(application.app, host=hostStr, port=8034, threads=8) # no major improvement from 4 to 16
serve(application.getApp(appEnv), host=hostStr, port=8034, threads=8) # no major improvement from 4 to 16
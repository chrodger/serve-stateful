
# http://www.gevent.org/servers.html


from gevent.pywsgi import WSGIServer
from gevent.pool import Pool
import application

pool = Pool(8000)
http_server = WSGIServer(('localhost', 8034), application.app, spawn=pool)
http_server.serve_forever()
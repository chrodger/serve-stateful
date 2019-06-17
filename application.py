
# create requirements.txt with (no shell required, run from serv-stateful-model dir):
# pipenv lock -r > requirements.txt

# stress test locally with apache ab (using windows powershell):
# C:\apache\httpd-2.4.39-o102s-x64-vc14\Apache24\bin> .\ab -n 1000 -c 10 http://localhost:8034/model


from keras.models import load_model
import numpy as np

from cassandra.cluster import Cluster

from flask import Flask, request
from flask_restful import Api, Resource, reqparse
import json
import os
import random
from datetime import datetime

def getApp(env):

    print(env)

    # Set up Cassandra connection.
    if(env == "local"):
        minUserId = 0
        maxUserId = 3
        numRecentVisitsToRetrieve = 5
        cluster = Cluster()
        session = cluster.connect()
        session.execute("use keyspace_state_aa;")
        rows = session.execute('select * from model_state')
        print('cassandra model_state rows:' + str(rows.current_rows.__len__()))
    else:
        minUserId = 0
        maxUserId = (1000 * 1000) - 1
        numRecentVisitsToRetrieve = 5
        session = 1

    modelPath = os.path.join(os.getcwd(), "models", 'keras-model00.h5')
    # model = load_model(".\\keras-boston-model00.h5")
    model = load_model(modelPath)
    model._make_predict_function()

    app = Flask(__name__)
    api = Api(app)


    class Model(Resource):

        def get(self):

            # Make some dummy calls to cassandra
            userId = random.randint(minUserId, maxUserId+1)
            # call 1: get model state for user
            rows1 = session.execute('select * from model_state where user_id = %s;', [userId])
            # call 2: get most recent visits for user
            rows2 = session.execute('select * from model_state where user_id = %s limit ' + str(numRecentVisitsToRetrieve) + ';', [userId])
            # call 3: record a new visit for user
            ts = datetime.now()
            features = "WXYZ" * 3
            insertStatus = session.execute('insert into user_visits(user_id, ts, features) values (%s, %s, %s);', [userId, ts, features])

            features = np.asarray([[1.0]*13])
            score = model.predict(features[0:1])[0].tolist()
            print(score)
            ret = {
                "score":json.dumps(score)
            }
            return ret, 201

        def post(self):
            # parser = reqparse.RequestParser()
            # parser.add_argument("name")
            # parser.add_argument("occupation")
            # args = parser.parse_args()
            #
            # ret = {
            #     "foo":args["name"],
            #     "bar":args["occupation"]
            # }
            # return ret, 201
            str = request.data.decode("utf-8")
            features = np.asarray([list(map(float, str.split(",")))])
            # print(features)
            score = model.predict(features[0:1])[0].tolist()
            # print(request.data)
            # print(score)
            ret = {
                "score":json.dumps(score)
            }

            return ret, 201

    api.add_resource(Model, "/model")
    # app.run(debug=True, host=hostStr, port=8034) # debug=True also enables reloader
    # app.run(debug=False, host=hostStr, port=8034, threaded=False) # faster ?!!
    # app.run(debug=False, host=hostStr, port=8034, threaded=True)

    # app.run(debug=False, host=hostStr, port=8034, threaded=False, processes=6) # doesn't work on Windows

    # m.predict(x_test[1:2])

    return app
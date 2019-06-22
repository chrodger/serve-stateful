
# create requirements.txt with (no shell required, run from serv-stateful-model dir):
# pipenv lock -r > requirements.txt

# stress test locally with apache ab (using windows powershell):
# C:\apache\httpd-2.4.39-o102s-x64-vc14\Apache24\bin> .\ab -n 1000 -c 10 http://localhost:8034/model


from keras.models import load_model
import numpy as np

from cassandra.cluster import Cluster

from flask import Flask, request
from flask_restful import Api, Resource, reqparse
import os
import random
from datetime import datetime
import json



modelPath = os.path.join(os.getcwd(), "models", 'keras-model00.h5')
# model = load_model(".\\keras-boston-model00.h5")
model = load_model(modelPath)
model._make_predict_function()

app = Flask(__name__)
api = Api(app)


class Model(Resource):

    def get(self):
        # features = np.asarray([[1.0]*13])
        features = np.random.rand(13)
        print(features)
        score = model.predict(features[0:1])[0].tolist()
        print(score)
        ret = {
            "score":json.dumps(score)
        }
        return ret, 201

    def post(self):
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

if __name__ == '__main__':
    # app.run(debug=False, threaded=False, processes=4) # ValueError: Your platform does not support forking.
    app.run(debug=False)

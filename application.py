
# create requirements.txt with (no shell required, run from serv-stateful-model dir):
# pipenv lock -r > requirements.txt

# stress test locally with apache ab (using windows powershell):
# C:\apache\httpd-2.4.39-o102s-x64-vc14\Apache24\bin> .\ab -n 1000 -c 10 http://localhost:8034/model


from keras.models import load_model
import numpy as np

from flask import Flask, request
from flask_restful import Api, Resource, reqparse
import json
import os


modelPath = os.path.join(os.getcwd(), "models", 'keras-model00.h5')
# model = load_model(".\\keras-boston-model00.h5")
model = load_model(modelPath)
model._make_predict_function()

app = Flask(__name__)
api = Api(app)


class Model(Resource):

    def get(self):
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

# call locally with:
# $ curl -X GET http://localhost:5000/model -i
# or:
# $ curl -X POST -H "Content-Type: application/json" http://localhost:5000/model -d '{"vec":[[24], [253], [215], [215], [38645],
# [686], [956], [2640], [89970], [325], [967], [325], [12909], [300], [8645], [18645], [686], [2252], [759], [667], [1823], [25458],
# [408], [56222], [4199], [8007], [948], [481], [586], [379], [742], [767], [742]]}' -i

# stress test locally with apache ab (using windows powershell):
# C:\apache\httpd-2.4.39-o102s-x64-vc14\Apache24\bin> .\ab -n 1000 -c 10 http://localhost:8034/model

# create requirements.txt with (no shell required, run from serv-stateful-model dir):
# pipenv lock -r > requirements.txt
# UPDATE: pipenv lock is not necessary
# On deployed vm, just do pipenv install




from keras.models import load_model
import numpy as np

from flask import Flask, request
from flask_restful import Api, Resource
import os
import json

from triplet_loss_cross import triplet_loss_cross



# modelPath = os.path.join(os.getcwd(), "models", 'keras-model00.h5')
modelPath = os.path.join(os.getcwd(), "models", 'my_model26attr_outrelu20_alpha30.h5')
model = load_model(modelPath, custom_objects={'Loss': triplet_loss_cross})
model._make_predict_function()

app = Flask(__name__)
api = Api(app)


class Model(Resource):

    def get(self):
        # features = np.asarray([[1.0]*13])
        features = np.asarray([
            [[24]], [[253]], [[215]], [[215]], [[38645]], [[686]], [[956]], [[2640]], [[89970]], [[325]], [[967]], [[325]], [[12909]], [[300]],
            [[8645]], [[18645]], [[686]], [[2252]], [[759]], [[667]], [[1823]], [[25458]], [[408]], [[56222]], [[4199]],
            [[8007]], [[948]], [[481]], [[586]], [[379]], [[742]], [[767]], [[742]]
        ])

        j = json.loads(
            '{"vec":[[24], [253], [215], [215], [38645], [686], [956], [2640], [89970], [325], [967], [325], [12909], [300],' +
            '[8645], [18645], [686], [2252], [759], [667], [1823], [25458], [408], [56222], [4199],' +
            '[8007], [948], [481], [586], [379], [742], [767], [742]]}'
        )
        # print(features)
        # score = model.predict(features[0:1])[0].tolist()
        #score = model.predict(features[0:33]).tolist()
        score = model.predict(j["vec"])
        # print(score.tolist())
        ret = {
            "score":json.dumps(score.tolist())
        }
        return ret, 201

    def post(self):

        # str = request.data.decode("utf-8")
        # features = np.asarray([list(map(float, str.split(",")))])
        # # print(features)
        # score = model.predict(features[0:1])[0].tolist()
        # # print(request.data)
        # # print(score)


        # print(request.data)
        # str = request.data.decode("utf-8")
        # print(str)
        # j = json.loads(str)
        j = request.get_json()
        # print(j)
        embedding = model.predict(j["vec"])
        ret = {
            "score":json.dumps(embedding.tolist())
        }
        return ret, 201

api.add_resource(Model, "/model")

if __name__ == '__main__':
    # app.run(debug=False, threaded=False, processes=4) # ValueError: Your platform does not support forking.
    app.run(debug=False)

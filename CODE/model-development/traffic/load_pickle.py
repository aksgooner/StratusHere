import pickle
import numpy as np
from latlon_to_xy import convertlatlon


with open('Traffic_predict.pickle', 'rb') as handle:
    model = pickle.load(handle)

# lat_input = input('Lat:')
# lon_input = input('Long:')
lat_input = 33.753746
lon_input = -84.386330
input_loc = [lat_input, lon_input]
print('The location you choose is ', str([lat_input, lon_input]))
Xt = convertlatlon(lat_input,lon_input)
Xt = np.asarray(Xt).reshape(1,-1)
AADT_predict = model.predict(Xt)
print('The predicted AADT is ', str(AADT_predict))

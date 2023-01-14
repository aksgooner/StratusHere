import pandas as pds
import numpy as np
from sklearn.gaussian_process import GaussianProcessRegressor
from sklearn.gaussian_process.kernels import DotProduct, RBF
from latlon_to_xy import convertlatlon
import pickle

class AADT_GPR:

    filepath='traffic_clean.csv'

    data = pds.read_csv(filepath,usecols= ['Station ID','Lat','Long','AADT_2021','AADT_2020','AADT_2019','AADT_2018','AADT_2017'])
    # businessloc=pds.read_csv('atl_companies-lon-lat-clean.csv',usecols= ['latitude','longtitude'])
    # print(data)
    lat, long= data['Lat'].to_numpy(), data['Long'].to_numpy()
    # lat_tar,long_tar = businessloc['latitude'].to_numpy(), businessloc['longtitude'].to_numpy()
    # loc=np.stack((lat_tar[:10],long_tar[:10]),axis=1)
    # print(loc)
    # print(pds.DataFrame(loc, columns = ['Lat','Long']))
    AADT = data['AADT_2021'].to_numpy()
    X = convertlatlon(lat,long)
    X = np.transpose(X)
    # Xt = convertlatlon(lat_tar,long_tar)
    # Xt = np.transpose(Xt)
    # print(X)
    y = AADT
    # print(y)
    kernel = DotProduct()+RBF()
    # # print(Xt[:10,:])
    gpr = GaussianProcessRegressor(kernel = kernel,n_restarts_optimizer=5,random_state=1,normalize_y=True).fit(X, y)

# print(gpr.score(X, y))
# lat_input = input('Lat:')
# lon_input = input('Long:')
# input_loc = [lat_input, lon_input]
# Xt = convertlatlon(lat_input,lon_input)
# Xt = np.transpose(Xt)
model = AADT_GPR()
with open('Traffic_predict.pickle', 'wb') as handle:
    pickle.dump(model.gpr, handle)
# AADT_predict = model.gpr.predict(Xt)
# print(AADT_predict.transpose())
# exportarray = np.stack((lat_tar.transpose(),long_tar.transpose(),AADT_predict.transpose()),axis=1)
# exportdata = pds.DataFrame(exportarray, columns = ['Lat','Long','AADT_predict'])
# print(exportdata)
# exportdata.to_csv('traffic_output.csv',index=False)

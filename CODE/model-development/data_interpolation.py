import pandas as pds
import numpy as np
from latlon_to_xy import convertlatlon
from sklearn.gaussian_process import GaussianProcessRegressor
from sklearn.gaussian_process.kernels import DotProduct, WhiteKernel



filepath='traffic_clean.csv'

data = pds.read_csv(filepath,usecols= ['Station ID','Lat','Long','AADT_2021','AADT_2020','AADT_2019','AADT_2018','AADT_2017'])
# print(data)
lat, long= data['Lat'].to_numpy(), data['Long'].to_numpy()
AADT = data['AADT_2021'].to_numpy()
X = convertlatlon(lat,long)
X = np.transpose(X)
print(X)
y = AADT
kernel = DotProduct() + WhiteKernel()
gpr = GaussianProcessRegressor(kernel = None,random_state=0).fit(X, y)
print(gpr.score(X, y))
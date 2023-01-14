import numpy as np
import pyproj


def convertlatlon (lat,lon):
    lat0 = 	33.753746
    lon0 = -84.386330
    # NAD83=pyproj.Proj("EPSG:3453",preserve_units = False)#False = meters #Louisiana South (ftUS)
    NAD83 = pyproj.Proj('+proj=utm +zone=10 +ellps=WGS84',
                        preserve_units=False)  # False = meters #Louisiana South (ftUS)
    x_ori, y_ori = NAD83(lon0, lat0)  # define x,y origin using lat0,lon0 in meters
    # print(x_ori)
    # print(y_ori)

    rearth = 6373.3 * 1000  # at lat0 = 29., in meters

    x1, y1 = NAD83(lon, lat)
    # print(x1 - x_ori, y1 - y_ori)
    return (x1 - x_ori)/1000, (y1 - y_ori)/1000
    # unit:km

# X,Y = convertlatlon(np.array([21,21.5,22,22.5]),np.array([-80,-80.1,-80.1,-80.2]))

# print(X,Y)

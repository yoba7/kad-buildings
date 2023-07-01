# -*- coding: utf-8 -*-
"""
Created on Thu Sep  1 10:51:51 2022

@author: Youri.Baeyens
"""

####
#
# 1. Environnement
#
####

# %% Import packages

from mygeodb.functions import download,getLogger,unzip
from mygeodb.geodatabase import Geodatabase as gdb

import os
import logging

from time import time

# Change current working directory

os.chdir(r'/home/yoba/NVMe/DataScience/data/Open-Data/kad_buildings/prg')

# %% Set logging

getLogger('../log/kad_buildings')

# %% Config

import config

# %% Create or connect to geodabatase

db=gdb('../output/kad_buildings.sqlite')

# %% Download Land registry open-data
# It is a zip file
# The zip file contains a set of shapefiles

#download(config.openDataSource,config.openDataDownload,if_exists='exit')

# %% Unzip file

#unzip(zipped=config.openDataDownload,unzipped=config.openDataUnzip)

# %% Load the relevant shapefiles into the geodatabase

for shapefile in config.shapefiles:
    db.loadShp(f'{config.openDataUnzip}/{shapefile}', shapefile,encoding='latin1')
    db.createSpatialIndex(f'{shapefile}')

# %% Create t02_agdp_parcels table
# This table is the union of 3 imported shapefiles
# t02_agdp_parcels contains 2 geometries:
#  - geometry = the geometry of the parcel (plot)
#  - pointOnSurface = st_pointOnSurface(parcels.geometry)

db.executeScript('t02_agdp_parcels')
db.recoverGeometry('t02_agdp_parcels')
db.createSpatialIndex('t02_agdp_parcels')
db.recoverGeometry('t02_agdp_parcels',geometry='pointOnSurface')
db.createSpatialIndex('t02_agdp_parcels',geometry='pointOnSurface')

# %% Create t02_agdp_buildings
# This table is the union of regional and cadastral shapefiles
# Those 2 variables are computed:
# - MD5Checksum(buildings.geometry) as id_building
# - st_pointOnSurface(buildings.geometry) as pointOnSurface

db.executeScript('t02_agdp_buildings')
db.recoverGeometry('t02_agdp_buildings')
db.createSpatialIndex('t02_agdp_buildings')
db.recoverGeometry('t02_agdp_buildings',geometry='pointOnSurface')
db.createSpatialIndex('t02_agdp_buildings',geometry='pointOnSurface')


# %% Links between buildings and parcels

db.executeScript('t03_agdp_buildings2parcels')

# %% Join of t02_agdp_parcels and t03_agdp_buildings2parcels

db.executeScript('t04_agdp_parcels')
db.recoverGeometry('t04_agdp_parcels')
db.createSpatialIndex('t04_agdp_parcels')
db.recoverGeometry('t04_agdp_parcels',geometry='pointOnSurface')
db.createSpatialIndex('t04_agdp_parcels',geometry='pointOnSurface')

# %% Find parcels with "building only parcels"

db.executeScript('t05_parcels_within_parcels')

# %% Update t04_agdp_parcels

db.executeScript('update of t04_agdp_parcels')


# %% Create t06_parcels_connections

import pandas as pd

db.database.execute('drop table if exists t06_parcels_connections')

db.database.execute('''
create table t06_parcels_connections (
    capakey_a,
    capakey_b,
    fl_intersects,
    geometry,
    ms_distance
)
''')


# %% Function to identify links for a few parcels

def processCapakeys(capakeys):
    
    parcels=','.join(["'"+capakey+"'" for capakey in capakeys])
    
    db.executeScript('t06_parcels_connections_parcel',
                     distance=config.distance,
                     parcels=parcels)

# %% Get list of all parcels with a building telling more than 50 m²


capakeys=pd.read_sql('''
select capakey
from t04_agdp_parcels
where ms_area_buildings_total>50
''',db.database)

capakeys2process=[row.capakey for row in capakeys.itertuples()]

start=time()
batchSize=50000
batchCount=round(len(capakeys2process)//batchSize)
b=0

while len(capakeys2process) > 0:
    
    b=b+1
    elapseEstimate=round((time()-start)/b*batchCount)
    remainingEstimate=round(elapseEstimate-(time()-start))
    remainingPercent=round(remainingEstimate/(elapseEstimate+1)*1000)/10
    logging.info(f'Batch: {b} - Elape estimate (seconds)={elapseEstimate} - Remaining estimate (seconds)={remainingEstimate} - {remainingPercent}%')
    
    batch = capakeys2process[:batchSize]
    capakeys2process = capakeys2process[batchSize:]
    
    processCapakeys(batch)



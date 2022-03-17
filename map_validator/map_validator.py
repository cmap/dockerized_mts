import os
import sys
import pandas as pd
import io


REQUIRED_FIELDS = {
  'pert_dose',
  'pert_id',
  'pert_plate',
  'pert_iname',
  'pert_type',
  'x_project_id',
  'pert_vehicle',
  'pert_well',
  'pert_dose_unit'
}

def validate(map_src,verbose=False,isFile=True):

    mapfile = None
    if(isFile):
        mapfile = pd.read_csv(map_src, sep='\t')
    else:
        mapfile = pd.read_csv(io.BytesIO(map_src),encoding='utf8',sep='\t')

    map_hds = set(mapfile.columns)

    if verbose:
        print(REQUIRED_FIELDS)
        print(map_hds)

    missing_fields = REQUIRED_FIELDS.difference(map_hds)
    return missing_fields


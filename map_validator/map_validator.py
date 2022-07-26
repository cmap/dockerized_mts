import os
import sys
import pandas as pd
import io
import re

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

""" 
Validate required fields exist 
"""
def validate_required_fields(map_src, verbose=False, isFile=True):
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

"""
Inactive function to auto fix the pert_ids
"""
def fix_pert_ids(map_src):
    map_src['pert_id'] = map_src['pert_id'].apply(lambda pert: re.sub(' ', '-', pert).upper())
    return map_src

""" 
Validate pert_ids since they are used to create compound keys and folder structure 
"""
def validate_pert_ids(map_src, verbose=False, isFile=True):
    if (isFile):
        mapfile = pd.read_csv(map_src, sep='\t')
    else:
        mapfile = pd.read_csv(io.BytesIO(map_src), encoding='utf8', sep='\t')

    invalid_perts = []
    for i, pert_id in mapfile['pert_id'].items():

        if ' ' in pert_id:
            invalid_perts.append(
                {'index': i,
                 'pert_id': pert_id,
                 'reason': 'pert_ids can not contain spaces'
                 }
            )
        elif pert_id != pert_id.upper():
            invalid_perts.append(
                {'index': i,
                 'pert_id': pert_id,
                 'reason': 'pert_ids must be uppercase'
                 }
            )

    return invalid_perts

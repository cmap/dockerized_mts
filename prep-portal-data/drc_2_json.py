import os
import json
import sys
from math import log2

import numpy as np
import pandas as pd

def calc_drc_points(row, n):
    xx = np.linspace(log2(row['min_dose']), log2(row['max_dose']), 40)
    yy = [round(dr_func(row, x), 10) for x in xx]
    points = {}
    points['x'] = xx
    points['y'] = yy
    return points

def dr_func(d, x):
    return float(d["lower_limit"]) + (float(d["upper_limit"]) - float(d["lower_limit"]))/(1 + (2**x/float(d["ec50"]))**float(d["slope"]))


def main(drc_file, l4_file, out_file):
    l4 = pd.read_csv(l4_file)

    drc = pd.read_csv(drc_file)
    points = drc.apply(lambda row: calc_drc_points(row, 40), axis=1)
    out = {"result":[]}
    print(drc)


    for i,row in drc.iterrows():
        out["result"].append(dict(row))

    #write to json
    with open(out_file, 'w') as fp:
        json.dump(out, fp)
        
if __name__ == "__main__":
    args = sys.argv[1:]
    if not (len(args) == 3):
        print("usage: drc_2_json [drc_table_path] [level4_lfc_path] [outfile]")

    drc_file, l4_file, out_file = sys.argv[1], sys.argv[2], sys.argv[2]
    
    main(drc_file,l4_file, out_file)
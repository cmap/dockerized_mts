"""
Prepare data for upload to Data Warehouse
"""
import logging
import os
import re
import json
import simplejson
import sys
import argparse
import numpy as np
import pandas as pd
from math import log2

logger = logging.getLogger('prep-portal-data')

REQUIRED_COLUMNS = [
    'screen',
    'pert_plate',
    'pert_id',
    'project',
    'parti_col',
    'insertionDate'
]

def build_parser():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--drc', '-d', help='DRC_TABLE file')
    parser.add_argument('--out', '-o', help='Output file')
    parser.add_argument('--screen', '-sc', help='Screen')
    parser.add_argument('--pert_plate', '-pp', help='Pert Plate')
    parser.add_argument('--pert_id', '-id', help='Pert ID')
    parser.add_argument('--project', '-pj', help='Pert ID')

    parser.add_argument(
        "--verbose", '-v',
        help="Whether to print a bunch of output",
        action="store_true",
        default=False
    )
    return parser


"""

"""
def calc_drc_points(row, n):
    xx = np.linspace(log2(row['min_dose']), log2(row['max_dose']), 40)
    yy = [round(dr_func(row, x), 10) for x in xx]
    points = {}
    points['x'] = list(xx)
    points['y'] = list(yy)
    return points

def dr_func(d, x):
    return float(d["lower_limit"]) + (float(d["upper_limit"]) - float(d["lower_limit"]))/(1 + (2**x/float(d["ec50"]))**float(d["slope"]))

def char_to_number(char):
    char_val = ord(char) - ord('A')
    return char_val


"""
Hash function to convert screen code to partition column.

Max number of partitions is 4000
Convention:
MTS
CPS





Calculate based on max code of "ZZZZZZ999"
"""
def screen_to_parti_col(screen):
    MAX_PARTITION_VALUE = 3*(10**15) #greater than "ZZZZZZ999"

    mo = re.match("([A-Z]+)([0-9]+)", screen.upper())
    project = mo[1]
    numbers = mo[2]

    parti_col = ""
    for char in project:
        parti_col += "{:02d}".format(char_to_number(char))

    #max 3 characters
    parti_col += "{:03d}".format(int(numbers))[-3:]


    return int(parti_col)

def add_required_cols(df):
    if not 'screen' in df.columns:


    'pert_plate',
    'pert_id',
    'project',
    'parti_col',
    'insertionDate'



def prep_drc(args):
    drc = pd.read_csv(args.drc)
    drc['points'] = drc.apply(lambda row: calc_drc_points(row, 40), axis=1)
    out = drc.to_dict('records')
    # write to json
    with open(args.out, 'w') as fp:
        simplejson.dump(out, fp, ignore_nan=True)
    logging.info("DRC JSON complete: " + args.out)
    return

def main(args):
    #prep_drc(args)

    parti_col = screen_to_parti_col(args.screen)
    print(parti_col)
    return


if __name__ == "__main__":
    args = build_parser().parse_args(sys.argv[1:])

    level = (logging.DEBUG if args.verbose else logging.INFO)
    logging.basicConfig(level=level)
    logger.info("args:  \n{}".format(args))

    main(args)

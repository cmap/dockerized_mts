"""
Convert compound CSVs to GCT format
"""

import os
import re
import sys
import glob
import logging
import argparse
import pandas as pd
import json

import cmapPy
from cmapPy.pandasGEXpress.GCToo import GCToo
from cmapPy.pandasGEXpress.parse import parse
from cmapPy.pandasGEXpress.write_gct import write as write_gct
from cmapPy.pandasGEXpress.write_gctx import write as write_gctx

import drc_2_json as drc

DEFAULT_COL_METADATA_HEADERS = ['profile_id', 'prism_replicate', 'pert_iname',
           'pert_id', 'pert_dose', 'pert_dose_unit', 'pert_idose',
           'pert_itime', 'pert_mfc_desc', 'pert_plate', 'pert_time',
           'pert_time_unit', 'pert_type', 'pert_vehicle', 'pert_well',
          'x_group_by', 'x_mixture_contents', 'x_mixture_id', 'x_project_id']

DEFAULT_ROW_METADATA_HEADERS = ['rid', 'ccle_name', 'pool_id', 'culture']

logger = logging.getLogger('pivot_splits')

def build_parser():
    parser = argparse.ArgumentParser(description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
        add_help=False)

    required_args = parser.add_argument_group('required arguments')
    required_args.add_argument('--splits_dir', '-d', help='Output folder of split module', required=True)
    required_args.add_argument('--project', '-pr', help='Project name', required=True)
    required_args.add_argument('--pert_plate', '-pp', help='Pert plate', required=True)
    required_args.add_argument('--pert', '-p', help='Pert ID', required=True)
    required_args.add_argument('--search_pattern', '-s',
        help='Search pattern within build_path/project/pert_plate/pert \n (default: %(default)s)',
        default='*LEVEL4*.csv')

    optional = parser.add_argument_group('optional arguments')
    optional.add_argument('--data_header', '-dhd', help='Columns required for data (default: %(default)s)', default='LFC')
    optional.add_argument('--cid_header', '-chd', help='Columns for column metadata. (Default: %(default)s)', default = 'profile_id')
    optional.add_argument('--rid_header', '-rhd', help='Columns for row metadata. (Default: %(default)s)', default = 'rid')
    optional.add_argument('--col_metadata_headers', '-cmh',
        help='Columns that belong in col_metadata_df',
        default=','.join(DEFAULT_COL_METADATA_HEADERS),
    )
    optional.add_argument('--row_metadata_headers', '-rmh',
        help='Columns that belong in row_metadata_df',
        default=','.join(DEFAULT_ROW_METADATA_HEADERS)
    )
    write_gct_opt = optional.add_mutually_exclusive_group()
    write_gct_opt.add_argument('--write_gctx', help='Use HDF5 based GCTX format',
            action='store_false', default=False)
    write_gct_opt.add_argument('--write_gct', help='Use text based GCT format (default)',
            action='store_true', dest='write_gctx', default=True)
    append_dims_grp = optional.add_mutually_exclusive_group()
    append_dims_grp.add_argument('--append_dims', help='Add dimensions to filename (default: true)',
            action='store_true', default=True)
    append_dims_grp.add_argument('--no-append-dims', help='',
            action='store_false', dest='append_dims')
    optional.add_argument("--verbose", '-v', help="Whether to print a bunch of output", action="store_true", default=False)
    optional.add_argument("-h", "--help", action="help", help="show this help message and exit")
    return parser






def main(args):
    return


if __name__ == "__main__":
    args = build_parser().parse_args(sys.argv[1:])

    level = (logging.DEBUG if args.verbose else logging.INFO)
    logging.basicConfig(level=level)
    logger.info("args:  \n{}".format(args))

    main(args)

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

def concat_unique_values(s, sep='|'):
    uniq_vals = s.unique()
    return sep.join(uniq_vals)

def write_gctoo(gctoo, filename, append_dims=True, use_gctx=True):
    nr,nc = gctoo.data_df.shape

    writer = (write_gctx if use_gctx else write_gct)
    if append_dims:
        writer(gctoo, '{}_n{}x{}'.format(filename, nc, nr))
    else:
        writer(gctoo,filename)


def csv2gctoo(df, rid_header, cid_header, data_header, col_metadata_headers, row_meta_headers):
    data_df = df[
        [cid_header, rid_header, data_header]
    ].pivot_table(
        index=rid_header,
        columns=cid_header,
        values=data_header
    )

    col_metadata_df = df[col_metadata_headers]
    row_metadata_df = df[row_meta_headers]
    col_metadata_df = col_metadata_df.groupby(cid_header).agg(concat_unique_values)
    row_metadata_df = row_metadata_df.groupby(rid_header).agg(concat_unique_values)

    gct_obj = GCToo(data_df = data_df, col_metadata_df = col_metadata_df, row_metadata_df = row_metadata_df)
    return gct_obj

def main(args):
    pert = args.pert
    pert_clean = re.sub('[^0-9a-zA-Z\-\_]+', '', pert.replace('|', '_')) #filenames should not contain '|'

    pert_directory = os.path.join(args.splits_dir, args.project, args.pert_plate, pert_clean)
    fstr = os.path.join(pert_directory, '*LEVEL4*.csv')
    fmatch = glob.glob(fstr)
    assert (len(fmatch) > 0) , "No files found: {}".format(fstr)
    assert (len(fmatch) == 1) , "Too many files found"

    csv_path = fmatch[0]

    df = pd.read_csv(csv_path)

    col_hds = args.col_metadata_headers.split(',')
    row_hds = args.row_metadata_headers.split(',')

    col_hds = list(set(col_hds).intersection(df.columns))
    col_hds_missing = set(col_hds).difference(df.columns)

    if len(col_hds_missing) > 0:
        logger.info("Columns missing from row_metadata_headers:\n{}".format(row_hds_missing))

    row_hds = list(set(row_hds).intersection(df.columns))
    row_hds_missing = set(row_hds).difference(df.columns)

    if len(row_hds_missing) > 0:
        logger.info("Columns missing from row_metadata_headers:\n{}".format(row_hds_missing))

    gct_obj = csv2gctoo(
        df = df,
        rid_header = args.rid_header,
        cid_header = args.cid_header,
        data_header = args.data_header,
        col_metadata_headers = col_hds,
        row_meta_headers = row_hds
    )

    write_gctoo(gct_obj, os.path.join(pert_directory, "LEVEL4_LFC_{}".format(pert_clean)), append_dims=args.append_dims, use_gctx=args.write_gctx)


if __name__ == "__main__":
    args = build_parser().parse_args(sys.argv[1:])

    level = (logging.DEBUG if args.verbose else logging.INFO)
    logging.basicConfig(level=level)
    logger.info("args:  \n{}".format(args))

    main(args)

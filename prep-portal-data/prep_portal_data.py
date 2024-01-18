"""
Prepare data for upload to Data Warehouse
"""
import logging
import os
import re
import sys
import glob
import json
import datetime
import simplejson
import argparse
import numpy as np
import pandas as pd
from math import log2
from google.cloud import bigquery

import hashlib
import random


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
    parser.add_argument('--data_dir', '-d', help='Data Directory', required=False)
    parser.add_argument('--search_patterns', '-sp', help='Comma-separated list of search patterns in --data_dir',
                        default=None, required=False)
    parser.add_argument('--file', '-f', help='Individual file, adds required columns.', required=False, default=None)
    parser.add_argument('--drc', help='Individual file, DRC file. Adds points and required columns.', required=False, default=None)
    parser.add_argument('--out', '-o', help='Output folder', default=None)
    parser.add_argument('--outfile', '-of', help='Specify output path and filename', default=None)
    parser.add_argument('--screen', '-sc', help='Screen', required=True)
    parser.add_argument('--pert_plate', '-pp', help='Pert Plate', required=False, default=None)
    parser.add_argument('--pert_id', '-id', help='Pert ID', required=False, default=None)
    parser.add_argument('--project', '-pj', help='Project', required=False, default=None)
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
    xx_pts = np.linspace(row['min_dose'], row['max_dose'], 40)
    yy = [round(dr_func(row, x), 10) for x in xx]
    points = {
        'x': list(xx_pts),
        'y': list(yy)
    }
    return points

def dr_func(d, x):
    if pd.isnull(d["slope"]):
        return -666
    return float(d["lower_limit"]) + (float(d["upper_limit"]) - float(d["lower_limit"]))/(1 + (2**x/float(d["ec50"]))**float(d["slope"]))

def char_to_number(char):
    char_val = ord(char) - ord('A')
    return char_val

def hash_project_code(project, modulo):
    parti_col = ""
    for char in project:
        parti_col += "{:02d}".format(char_to_number(char))

    return int(parti_col) % modulo

"""
Hash function to convert screen code to partition column.

Max number of partitions is 4000
Convention:
MTS - 1-1000 (use the MTS number. Mod by 1000 add 1 if zero)
APS - 1001-2000 (use the APS number. Add 1001 mod 2000)
CPS- 2001-3000 (And so on)
OTHERS - 3001-3999
Calculate based on max code of "ZZZZZZ999"
"""
def screen_to_parti_col(screen):
    mo = re.match("([A-Z]+)([0-9]+)", screen.upper())

    if mo is None: #incase build is named in an odd way
        hash_code = hashlib.sha256(screen.encode()).hexdigest()
        hash_integer = int(hash_code, 16)
        return hash_integer % 1000 + 3000

    project = mo[1]
    numbers = mo[2]

    if (project == "MTS") or (project == "PMTS"):
        return int(numbers) % 1000
    elif project == "CPS":
        return int(numbers) % 1000 + 1 + 1000
    elif project == "APS":
        return int(numbers) % 1000 + 1 + 2000
    else:
        return hash_project_code(project, 1000) + 3000 #will assign based on assay series


def get_current_datetime():
    return datetime.datetime.now().strftime("%Y/%m/%d %H:%M:%S")

def add_required_cols(args, df, insertionDate):
    if args.pert_plate:
        df['pert_plate'] = args.pert_plate
    if args.pert_id:
        df['pert_id'] = args.pert_id
    if args.project:
        df['project'] = args.project

    df['screen'] = args.screen
    if not 'parti_col' in df.columns:
        df['parti_col'] = screen_to_parti_col(args.screen)
    if not 'insertionDate' in df.columns:
        df['insertionDate'] = insertionDate

    return df


def prep_and_write_drc(args, drc_fp, insertionDate):
    drc = pd.read_csv(drc_fp)
    drc.rename(columns={'varied_iname': 'pert_iname', 'varied_id': 'pert_id'}, inplace=True)
    sanitize_colnames(drc)
    drc['pts'] = drc.apply(lambda row: calc_drc_points(row, 40), axis=1)
    drc['ic50'] = drc.apply(lambda row: 2**row['log2_ic50'], axis=1)
    drc = add_required_cols(args, drc, insertionDate)

    table_name = os.path.splitext(os.path.basename(drc_fp))[0]
    drc = subset_columns_to_bq_table(drc, table_name)
    out = drc.to_dict('records')

    # write to json
    drc_filepath = os.path.join(args.out, 'dose_response_curves', '{}_dose_response_curves.json'.format(args.pert_id))
    os.makedirs(os.path.dirname(drc_filepath), exist_ok=True)
    with open(drc_filepath, 'w') as fp:
        simplejson.dump(out, fp, ignore_nan=True, indent=4*' ')

    logging.info("DRC JSON complete: " + args.out)
    return


def sanitize_colnames(df):
    df.columns = df.columns.str.replace(".", "_", regex=False)
    return


def get_table_columns(project_id, dataset_id, table_id):
    client = bigquery.Client()
    table_ref = f"{project_id}.{dataset_id}.{table_id}"
    table = client.get_table(table_ref)
    return [field.name for field in table.schema]


def catch_table_name_exceptions(table_name):
    """
    Catch exceptions for table names that are not the same as the BigQuery table names.
    """
    if table_name == "DRC_TABLE":
        return "dose_response_curves"
    elif "EPS_QC_TABLE" in table_name:
        return "eps_qc_table"
    elif "QC_TABLE" in table_name:
        return "qc_table"
    else:
        return table_name


def subset_columns_to_bq_table(df, table_name):
    """
        Subset the columns of a DataFrame to match the columns of a BigQuery table.

        This function takes a DataFrame and a table name as input, retrieves the list
        of columns for the specified BigQuery table, and returns a DataFrame with only
        the columns that are common to both the input DataFrame and the BigQuery table.

        Args:
            df (pandas.DataFrame): The input DataFrame.
            table_name (str): The name of the BigQuery table to match columns with.

        Returns:
            pandas.DataFrame: A DataFrame containing only the common columns.
        """
    project_id = 'prism-359612'
    dataset_id = os.environ["BQ_DATASET_ID"]
    table_id = catch_table_name_exceptions(table_name);

    print("Table Name: " + table_name)
    table_cols = get_table_columns(project_id, dataset_id, table_id)

    # Create a set of lowercase table columns
    table_cols_lower = set(map(str.lower, table_cols))

    # Find the intersection of lowercase DataFrame column names
    common_columns_lower = set(df.columns.str.lower()).intersection(table_cols_lower)

    # Preserve the original casing of the selected columns
    select_columns = [col for col in df.columns if col.lower() in common_columns_lower]

    print("Dataframe Columns: " + str(list(df.columns)))
    print("Table Columns: " + str(table_cols))
    print("Subsetting to common columns: " + str(select_columns))
    df = df[select_columns]
    return df


def read_write_files_with_required_columns(args, file, insertionDate):
    logging.info("Reading File from: " + file)
    df = pd.read_csv(file)
    df = add_required_cols(args, df, insertionDate=insertionDate)
    sanitize_colnames(df)

    table_name = os.path.splitext(os.path.basename(file))[0]
    df = subset_columns_to_bq_table(df, table_name)

    if len(df) > 0:
        if args.outfile:
            file_outpath = args.outfile
        else:
            if args.pert_id:
                filename = "{}_{}".format(args.pert_id, os.path.basename(file))
            else:
                filename = "{}".format(os.path.basename(file))

            file_outpath = os.path.join(
                args.out,
                os.path.splitext(os.path.basename(file))[0],
                filename)

        os.makedirs(os.path.dirname(file_outpath), exist_ok=True)
        df.to_csv(file_outpath, index=False)
        logging.info("File created: " + file_outpath)
    else:
        logging.info("File, {}, was empty. Skipping...".format(file))

    return

def main(args):
    #prep_drc(args)
    # os.makedirs(args.out, exist_ok=True)
    CURRENT_TIME = get_current_datetime()

    if args.search_patterns:
        sp = args.search_patterns.split(",")
        for s in sp:
            file = glob.glob(os.path.join(args.data_dir, "*"+s+"*"))[0]
            if "DRC" in s.upper():
                prep_and_write_drc(args, file, insertionDate=CURRENT_TIME)
            else:
                read_write_files_with_required_columns(args, file, insertionDate=CURRENT_TIME)
        return

    if args.file:
        read_write_files_with_required_columns(args, args.file, insertionDate=CURRENT_TIME)
        return

    if args.drc:
        prep_and_write_drc(args, args.drc, insertionDate=CURRENT_TIME)
        return

    report_files = glob.glob(
        os.path.join(args.data_dir, "reports_files_by_plot", "*", "*.csv")
    )
    for file in report_files:
        read_write_files_with_required_columns(args, file, insertionDate=CURRENT_TIME)

    drc_fp = glob.glob(os.path.join(args.data_dir, "DRC_TABLE*.csv"))
    if len(drc_fp) > 0:
        assert len(drc_fp) == 1, "Incorrect number of DRC_TABLE files found, expected 1 found: {}".format(len(drc_fp))
        drc_fp = drc_fp[0]
        prep_and_write_drc(args, drc_fp, insertionDate=CURRENT_TIME)
    else:
        logging.info("No DRC file found, skipping")

    logging.info("done")
    return


if __name__ == "__main__":
    parser = build_parser()
    args = parser.parse_args(sys.argv[1:])
    if not (args.data_dir or args.file):
        parser.error("--file or --data_directory required")

    level = (logging.DEBUG if args.verbose else logging.INFO)
    logging.basicConfig(level=level)
    logger.info("args:  \n{}".format(args))
    if (args.out is None) and (args.outfile is None):
        args.out = os.path.join(args.data_dir, "data-warehouse")
    main(args)

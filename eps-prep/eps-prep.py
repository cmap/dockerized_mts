"""
Module takes in a project directory for an Extended Day build and adapts it for EPS downloads

1. Removes all ic50 references
"""

import argparse
import glob
import logging
import os
import sys
import pandas as pd

logger = logging.getLogger('eps-prep')
biomarker_search_patterns = [
    '*continuous_association*',
    '*discrete_associations*',
    '*RF_table*',
    '*model_table*'
]


def build_parser():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('--project_dir', '-d', help="Project Directory", type=str, required=True)
    return parser


"""
Drops the ic50 column from the DRC_TABLE file, replaces file in place
"""
def remove_ic50_from_drc_table(project_dir):
    search_path = os.path.join(project_dir, "*", "data", "*DRC_TABLE*")
    file = glob.glob(search_path)
    assert(len(file) == 1), f"Expected to find one file matching pattern: {search_path}"
    df = pd.read_csv(file[0])
    if 'log2.ic50' in df.columns:
        df = df.drop(columns=['log2.ic50'])
        df.to_csv(file[0], index=False)
        return
    else:
        print("IC50 columns not present")


"""
Deletes the IC50_MATRIX file
"""
def delete_ic50_matrix_file(project_dir):
    search_path = os.path.join(project_dir, "*", "data", "*IC50_MATRIX*")
    file = glob.glob(search_path)
    if len(file) == 0:
        print("No IC50_MATRIX file found, skipping")
        return
    else:
        assert(len(file) == 1), f"Expected to find one file matching pattern: {search_path}"
        os.remove(file[0])
        return

"""
Removes all ic50 dose rows from biomarker files
"""
def remove_ic50_doses_from_biomarker(project_dir):
    for sp in biomarker_search_patterns:
        # matching project_dir/{PROJECT
        file = glob.glob(os.path.join(project_dir, "*", "data", sp))
        print(file)
        assert(len(file) == 1), "Expected to find one file matching pattern: {}".format(sp)
        df = pd.read_csv(file[0])
        # remove rows where pert_dose = 'log2.ic50' using .loc
        df = df.loc[df['pert_dose'] != 'log2.ic50']
        df.to_csv(file[0], index=False)
    return


def main(args):
    # remove_ic50_from_drc_table(args.project_dir)
    delete_ic50_matrix_file(args.project_dir)
    remove_ic50_doses_from_biomarker(args.project_dir)
    return

if __name__ == "__main__":
    args = build_parser().parse_args(sys.argv[1:])
    main(args)


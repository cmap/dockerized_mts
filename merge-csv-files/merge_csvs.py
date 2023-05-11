#!/usr/bin/env python

import argparse
import glob
import logging
import os
import sys
import pandas as pd

logger = logging.getLogger('merge-biomarker')


def build_parser():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('--data_dir', '-d', help="Path to directory containing csv files to concat", type=str, required=True)
    parser.add_argument('--out', '-o', help='Output directory', type=str, required=True)
    parser.add_argument('--search_pattern', '-s', help="search pattern for csv's",default='*', type=str, required=True)
    parser.add_argument('--separator', '-sp', help="File sperator defaults to ','", default=',',type=str)
    parser.add_argument('--addProjectName', '-ap', help="Whether to prepend the project name to the file", action="store_true", default=False)
    parser.add_argument('--verbose', '-v', help="Whether to print a bunch of output", action="store_true", default=False)
    return parser


def main(args):
    search_str = os.path.join(args.data_dir, args.search_pattern)
    if args.addProjectName:
        search_str = os.path.join(args.data_dir,"*/*",args.search_pattern)
        project_name = os.path.basename(args.data_dir)
        output_file = os.path.join(args.out,project_name + "_" + args.search_pattern)
    else:
        output_file = os.path.join(args.out, args.search_pattern).replace("*",".csv")

    matches = glob.glob(search_str)
    print("Found {} files".format(len(matches)))
    print("Files: {}".format(matches))
    dfs = []
    for filename in matches:
        print("Reading file: {}".format(filename))
        df = pd.read_csv(filename, index_col=None, header=0,sep=args.separator)
        dfs.append(df)


    if len(dfs) > 0:
        result = pd.concat(dfs, axis=0, ignore_index=True)
        result.to_csv(output_file, index=False,sep=args.separator)
        print("Wrote file: {}".format(output_file))
    return

if __name__ == "__main__":
    args = build_parser().parse_args(sys.argv[1:])
    main(args)


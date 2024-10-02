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
    parser.add_argument('--outfile', '-n', help='Output filename', type=str, required=False)
    parser.add_argument('--search_pattern', '-s', help="search pattern for csv's",default='*', type=str, required=True)
    parser.add_argument('--separator', '-sp', help="File sperator defaults to ','", default=',',type=str)
    parser.add_argument('--file_prefix', '-p', help="File prefix to prepend to output file name", default="",type=str);
    parser.add_argument('--addProjectName', '-ap', help="Whether to prepend the project name to the file", action="store_true", default=False)
    parser.add_argument('--verbose', '-v', help="Whether to print a bunch of output", action="store_true", default=False)
    return parser


def main(args):
    search_str = os.path.join(args.data_dir, args.search_pattern)
    if args.addProjectName:
        search_str = os.path.join(args.data_dir,"*/*",args.search_pattern)
        project_name = os.path.basename(args.data_dir)
        output_file = os.path.join(args.out, project_name + "_" + args.search_pattern)
    else:
        if args.outfile:
            output_file = os.path.join(args.out, args.outfile)  # filename override
        else:
            if args.file_prefix:  # expecting: "*DRC_TABLE*"
                output_file = args.file_prefix.rstrip("_") + "_" + args.search_pattern.replace("*","") + ".csv"
            else:
                output_file = args.search_pattern.replace("*","") + ".csv"  # expecting: "*DRC_TABLE*"
            output_file = os.path.join(args.out, output_file)

    matches = glob.glob(search_str)
    print("Found {} files".format(len(matches)))
    print("Files: {}".format(matches))
    dfs = []

    output_cols = []
    # create df with columns
    for filename in matches:
        sample = pd.read_csv(filename, index_col=None, header=0, sep=args.separator, nrows=0)
        for col in sample.columns:
            if col not in output_cols:
                output_cols.append(col)

    buffer_df = pd.DataFrame(columns=output_cols)
    write_header = True
    buffer_df.to_csv(output_file, mode='w', index=False, header=write_header, sep=args.separator)
    write_header = False  # write header only once

    for filename in matches:
        print("Reading file: {}".format(filename))
        df_chunks = pd.read_csv(filename, index_col=None, header=0, sep=args.separator, chunksize=10**6)
        for chunks in df_chunks:
            chunks = chunks.reindex(columns=output_cols)
            chunks.to_csv(output_file, mode='a', index=False, header=write_header, sep=args.separator)

        print(f"Wrote input {filename} to file : {output_file}")

    return


if __name__ == "__main__":
    args = build_parser().parse_args(sys.argv[1:])
    main(args)


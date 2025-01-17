#!/usr/bin/env python

import argparse
import re
import glob
import logging
import os
import sys
import pandas as pd

logger = logging.getLogger('collate-project-files')

# search patterns. will search for any occurrences in file name
# Some exceptions are made for LEVEL4_LFC and LEVEL5_LFC to avoid COMBAT
search_patterns = [
    "LEVEL3_",
    "LEVEL4_LFC",
    "LEVEL4_LFC_COMBAT",
    "LEVEL5_LFC",
    "LEVEL5_LFC_COMBAT",
    "DRC_TABLE",
    "model_table",
    "RF_table",
    "discrete_associations",
    "continuous_associations"
    "synergy_table"
    "bliss_mss_table"
]

def build_parser():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('--data_dir', '-d', help="Path to directory containing csv files to concat", type=str, required=True)
    parser.add_argument('--out', '-o', help='Output directory', type=str, required=True)
    parser.add_argument('--outfile', '-n', help='Output filename', type=str, required=False)
    parser.add_argument('--separator', '-sp', help="File seperator defaults to ','", default=',',type=str)
    parser.add_argument('--file_prefix', '-p', help="File prefix to prepend to output file name", default="",type=str)
    parser.add_argument('--addProjectName', '-ap', help="Whether to prepend the project name to the file", action="store_true", default=False)
    parser.add_argument('--project',  help="Replace 'x_project_id' with this value",type=str, required=True)
    parser.add_argument('--screen', help="Replace 'screen' field with this value",type=str, required=True)
    parser.add_argument('--verbose', '-v', help="Whether to print a bunch of output", action="store_true", default=False)
    return parser

def collate_files(matches, output_file, args):
    output_cols = []

    if len(matches) == 0:
        print("No files found for pattern")
        return

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
            if "x_project_id" in output_cols:
                chunks['x_project_id'] = args.project
            if "screen" in output_cols:
                chunks['screen'] = args.screen
            chunks.to_csv(output_file, mode='a', index=False, header=write_header, sep=args.separator)

        print(f"Wrote input {filename} to file : {output_file}")
        if "x_project_id" in output_cols:
            print(f"Changed x_project_id to {args.project}")
        if "screen" in output_cols:
            print(f"Changed screen to {args.screen}")
    return

def main(args):
    for search_pattern in search_patterns:
        glob_search = os.path.join(args.data_dir, "*/*", f"*{search_pattern}*")
        print("Searching for files with pattern: {}".format(glob_search))
        matches = glob.glob(glob_search)
        output_file = os.path.join(args.out, args.project + "_" + search_pattern + ".csv")
        if search_pattern == "LEVEL4_LFC":
            matches = [f for f in matches if "COMBAT" not in f]
        if search_pattern == "LEVEL5_LFC":
            matches = [f for f in matches if "COMBAT" not in f]

        #filter any gct files that are found
        matches = [f for f in matches if not f.endswith(".gct")]
        print("Found {} files".format(len(matches)))
        print("Files: {}".format(matches))

        collate_files(matches, output_file, args)


if __name__ == "__main__":
    args = build_parser().parse_args(sys.argv[1:])
    main(args)


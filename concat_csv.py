#!/usr/bin/env python

import argparse
import glob
import logging
import os
import sys
import pandas as pd

def build_parser():

    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    # The following arguments are required. These are files that are necessary for assembly and which change
    # frequently between cohorts, replicates, etc.
    parser.add_argument("--dir", "-d", help="Path to directory containing csv files to concat",
                        type=str, required=True)
    parser.add_argument("--search_pattern", "-s", help="search pattern for csvs",
                        default='*', type=str, required=True)

    parser.add_argument("--out", "-o", help="output file",
                        type=str, required=True)

    return parser


def main(args):
    search_str = os.path.join(args.dir, args.search_pattern)
    matches = glob.glob(search_str)

    dfs = [pd.read_csv(fp) for fp in matches]

    result = pd.concat(dfs)
    result.to_csv(args.out, index=False)


if __name__ == "__main__":
    args = build_parser().parse_args(sys.argv[1:])
    #setup_logger.setup(verbose=args.verbose)
    #ogger.debug("args:  {}".format(args))

    main(args)

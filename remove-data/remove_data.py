"""
Remove data from a single or set of files.
"""
import logging
import os
import re
import sys
import glob
import json
import argparse
import pandas as pd
from math import log2


logger = logging.getLogger('remove-data')

def build_parser():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--data_dir', '-d', help='Data Directory', required=False)
    parser.add_argument('--search_patterns', '-sp', help='Comma-separated list of search patterns in --data_dir',
                        default=None, required=False)
    parser.add_argument('--file', '-f', help='Individual file, adds required columns.', required=False, default=None)

    parser.add_argument('--field', action='append',
                        help='Field name of data to remove, maps to corresponding ordered --value')
    parser.add_argument('--value', action='append',
                        help='Value for the field, maps to corresponding ordered --field')

    parser.add_argument('--ignore-missing-fields', '-imf', help='Ignore missing fields', action='store_true',
                        default=False)
    parser.add_argument('--out', '-o', help='Output folder', default=None)
    parser.add_argument('--outfile', '-of', help='Specify output path and filename', default=None)
    parser.add_argument(
        "--verbose", '-v',
        help="Whether to print a bunch of output",
        action="store_true",
        default=False
    )
    return parser

def read_file(file):
    # read in file
    if file.endswith('.csv'):
        df = pd.read_csv(file)
    elif file.endswith('.tsv') or file.endswith('.txt'):
        df = pd.read_csv(file, sep='\t')
    elif file.endswith('.json'):
        df = pd.read_json(file)
    else:
        raise ValueError("File type not supported: {}".format(file))
    return df

def write_file(df, outfile):
    outfile_dir = os.path.dirname(outfile)
    if not os.path.exists(outfile_dir):
        os.makedirs(outfile_dir)
    # read in file
    if outfile.endswith('.csv'):
        df.to_csv(outfile, index=False)
    elif outfile.endswith('.tsv') or outfile.endswith('.txt'):
        df.to_csv(outfile, sep='\t', index=False)
    elif outfile.endswith('.json'):
        df.to_json(outfile, orient='records', indent=4)
    else:
        raise ValueError("File type not supported: {}".format(outfile))
    logger.debug("Wrote file: {}".format(outfile))

    return

def main(args):
    # Search for files
    if args.file and args.data_dir:
        files = [os.path.join(args.data_dir, args.file)]
    elif args.file:
        files = [args.file]
    elif args.data_dir and args.search_patterns:
        files = []
        for sp in args.search_patterns.split(","):
            files.extend(glob.glob(os.path.join(args.data_dir, sp)))

    # for each file
    for file in files:
        logger.debug("Reading file: {}".format(file))
        df = read_file(file)
        logger.debug("Length of original file: {}".format(len(df)))
        # for each field
        for field, value in zip(args.field, args.value):
            logger.debug("Removing {}={}".format(field, value))
            if field not in df.columns:
                if args.ignore_missing_fields:
                    logger.warning("Field {} not in file {}".format(field, file))
                    continue
                else:
                    raise ValueError("Field {} not in file {}. " +
                                     "See --ignore-missing-fields flag if acceptable".format(field, file))

            df = df[df[field] != value]

        logger.debug("Length of new file: {}".format(len(df)))

        if args.file and args.outfile:
            write_file(df, args.outfile)
        elif args.out:
            rel_path = os.path.relpath(file, args.data_dir)
            write_file(df, os.path.join(args.out, rel_path))
        else: #overwrite file if no output is specified
            write_file(df, file)
    return


if __name__ == "__main__":
    parser = build_parser()
    args = parser.parse_args(sys.argv[1:])
    if not (args.data_dir or args.file):
        parser.error("--file or --data_directory required")

    level = (logging.DEBUG if args.verbose else logging.INFO)
    logging.basicConfig(level=level)
    logger.info("args:  \n{}".format(args))

    main(args)

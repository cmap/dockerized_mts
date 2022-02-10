import argparse
import os
import sys

import pandas as pd

# read DataFrame
def build_parser():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    # The following arguments are required. These are files that are necessary for top_10_biomarker
    parser.add_argument("--data_dir", "-d", help="Required: Path to continuous association file",type=str, required=True)
    parser.add_argument("--out_dir", "-o", help="Required: out folder",type=str, required=True)
    parser.add_argument("--extract_top_x", "-x", help="Extract the top x results",type=str, default="10")
    parser.add_argument("--verbose", '-v', help="Whether to print a bunch of output", action="store_true", default=False)
    return parser

def build(args):
    top_x = args.extract_top_x
    if os.path.exists(args.data_dir):
        data = pd.read_csv(args.data_dir)
        top_x_biomarker_file_path =os.path.join(args.out_dir,'top_' + top_x + '_biomarkers.csv')
        data.reindex(data.coef.abs().sort_values(ascending=False).index)
        df = data.head(int(top_x))
        df.to_csv(top_x_biomarker_file_path, index=False)
    return

def main(args):
    try:
        build(args)
    except Exception as e:
        print(e)

if __name__ == "__main__":
    args = build_parser().parse_args(sys.argv[1:])
    print(args)
    main(args)

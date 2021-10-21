import argparse
import os
import sys

import pandas as pd

# read DataFrame
def build_parser():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    # The following arguments are required. These are files that are necessary for top_10_biomarker
    parser.add_argument("--file_name", "-f", help="Required: Path to continous association file",type=str, required=True)
    parser.add_argument("--out_dir", "-o", help="Required: out folder",type=str, required=True)
    parser.add_argument("--default_dataset", "-ds", help="The default dataset, will be used of association file does not have a dataset column",type=str)
    parser.add_argument("--verbose", '-v', help="Whether to print a bunch of output", action="store_true", default=False)
    return parser

def top_10(biomarker_table,out_path):
    biomarker_table.reindex(biomarker_table.coef.abs().sort_values(ascending=False).index)
    df = biomarker_table.head(10)
    df.to_csv(out_path, index=False)
    return
def build(args):
    data = pd.read_csv(args.file_name)
    path = args.out_dir
    if 'dataset' not in data.columns:
        dataset = args.default_dataset
        for pert_name, group in data.groupby(['pert_name']):
            single_pert(pert_name,dataset,group)
        return
    else:
        for (pert_name,dataset), group in data.groupby(['pert_name','dataset']):
            single_pert(pert_name,dataset,group)

    return

def single_pert(pert_name,dataset,group):
    d = f'{pert_name}'.lower().replace("(","").replace(")","").replace(" ","_")
    path = f'{dataset}'.lower()
    biomarker_parent_path = os.path.join(args.out_dir,'biomarker',f'{path}')
    top10_biomarker_parent_path= os.path.join(args.out_dir,'top-10-biomarker',f'{path}')

    os.makedirs(biomarker_parent_path, exist_ok=True)
    os.makedirs(top10_biomarker_parent_path, exist_ok=True)
    biomarker_file_path =os.path.join(biomarker_parent_path,f'{d}.csv')
    top_10_biomarker_file_path =os.path.join(top10_biomarker_parent_path,f'{d}.csv')
    group.to_csv(biomarker_file_path, index=False)
    top_10(group,top_10_biomarker_file_path)
    return

def main(args):
    try:
        build(args)
    except Exception as e:
        print(e)

if __name__ == "__main__":
    args = build_parser().parse_args(sys.argv[1:])
    main(args)

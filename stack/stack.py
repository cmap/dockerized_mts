import os
import re
import sys
import glob
import logging
import argparse
import pandas as pd
from cmapPy.pandasGEXpress.parse import parse

logger = logging.getLogger('stack')

def build_parser():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('--build_paths', '-b', help='Comma separated list of build paths to collate')
    parser.add_argument('--build_name', '-n', help='Build Name, prepended to files')
    parser.add_argument('--only_stack_keys', '-k', help='Comma separated list of keys. Useful if parallelizing, only listed keys will be concatenated')
    parser.add_argument('--sig_id_cols', '-s',
        help='Comma separated list of col names to create sig_ids if not present',
        default='pert_plate,culture,pert_id,pert_idose,pert_time',
        )
    #parser.add_argument('--ignore_missing', action="store_true", default=False)
    parser.add_argument('--out', '-o', help='Output for collated build')
    parser.add_argument("--verbose", '-v', help="Whether to print a bunch of output", action="store_true", default=False)

    return parser

def melt_and_concat_gcts(gct_paths):
    gct_data = []
    for gct_path in gct_paths:
        gct_data.append(parse(gct_path).data_df.reset_index().melt(id_vars='rid'))

    melted_gcts = pd.concat(gct_data)
    return melted_gcts

#Get dimensions from list of file_paths
def sum_dims_from_paths(file_paths):
    nc,nr = 0,0
    for fp in file_paths:
        match = re.search('n([0-9]+)x([0-9]+).*', fp)
        nc += int(match.group(1))
        nr += int(match.group(2))

    return nc,nr

"""
Make sig_ids based on id_cols.
"""
def make_sig_id(level5_table, id_cols):
    col_hds = id_cols.split(',')
    level5_table['sig_id'] = level5_table.apply(lambda row: '_'.join([str(row[col]) for col in col_hds]), axis=1)
    return level5_table

def main(args):
    build_contents_dict = {
        'inst_info' : {
            'search_pattern': '*_inst_info.txt',
            'type':'metadata'
        },
        'cell_info' : {
            'search_pattern': '*_cell_info.txt',
            'type':'metadata'
        },
        'QC_TABLE' : {
            'search_pattern': '*QC_TABLE*.csv',
            'type': 'report',
        },
        'compound_key' : {
            'search_pattern': '*compound_key.csv',
            'type': 'key'
        },
        'LEVEL2_COUNT': {
            'search_pattern': '*_LEVEL2_COUNT*.gctx',
            'type':'gctx'
        },
        'LEVEL2_MFI': {
            'search_pattern': '*_LEVEL2_MFI*.gctx',
            'type':'gctx'
        },
        'LEVEL3_LMFI': {
            'search_pattern': '*_LEVEL3_LMFI*.csv',
            'type':'csv_data'
        },
        'LEVEL4_LFC': {
            'search_pattern': '*_LEVEL4_LFC*.csv',
            'type':'csv_data'
        },
        'LEVEL5_LFC': {
            'search_pattern': '*_LEVEL5_LFC*.csv',
            'type':'csv_data'
        },
    }

    data_dict = {}

    out=args.out
    if not os.path.exists(out):
        os.makedirs(out)

    build_paths = args.build_paths.split(',')
    print("After args.build_paths.split()")
    nbuilds = len(build_paths)
    print("Number of builds: {}".format(nbuilds))

    if args.only_stack_keys:
        only_keys = args.only_stack_keys.split(',')
        print(only_keys)
        build_contents_dict = { key: build_contents_dict[key] for key in only_keys }
        print(build_contents_dict)

    build_name = args.build_name

    for key in build_contents_dict:
        print(key)
        result = map(lambda x: os.path.join(x, build_contents_dict[key]['search_pattern']), build_paths)
        fps = map(glob.glob, result)
        fps = [item for sublist in fps for item in sublist]
        #print(fps)
        assert len(fps) >= nbuilds, 'Files not found in build_paths'
        assert len(fps) == nbuilds, 'Too many files found for key: {}'.format(key)

        if build_contents_dict[key]['type'] == 'gctx':
            print('Melting and Merging the following files:\n\t{}'.format('\n\t'.join(fps)))
            combined_data = melt_and_concat_gcts(fps)
            nc, nr = nc, nr = sum_dims_from_paths(fps)
            out_path = os.path.join(out,'{}_{}_n{}x{}.csv'.format(build_name, key, nc, nr))
            print("Writing file to: \n\t{}".format(out_path))
            combined_data.to_csv(out_path, index=False)
        elif build_contents_dict[key]['type'] == 'csv_data':
            print('Merging the following files:\n\t{}'.format('\n\t'.join(fps)))
            combined_data = pd.concat([pd.read_csv(fp) for fp in fps]).reset_index(drop=True)
            combined_data['feature_id'] = combined_data.apply(lambda row: '{}:{}'.format(row['culture'], row['ccle_name']), axis=1)
            if key == 'LEVEL5_LFC':
                if not 'sig_id' in combined_data.columns:
                    logger.info('Sig ids not found in file, creating from sig_id_cols param')
                    combined_data = make_sig_id(combined_data, id_cols=args.sig_id_cols)
                prof_key = 'sig_id'
            else:
                prof_key='profile_id'
            nc = len(combined_data[prof_key].unique())
            nr = len(combined_data['feature_id'].unique())

            out_path = os.path.join(out,'{}_{}_n{}x{}.csv'.format(build_name, key, nc, nr))
            print("Writing file to: \n\t{}".format(out_path))
            combined_data.to_csv(out_path, index=False)

        elif build_contents_dict[key]['type'] == 'metadata':
            print('Merging the following files:\n\t{}'.format('\n\t'.join(fps)))
            combined_data = pd.concat([pd.read_csv(fp, sep='\t') for fp in fps]).reset_index(drop=True)

            out_path = os.path.join(out,'{}_{}.txt'.format(build_name, key))
            print("Writing file to: \n\t{}".format(out_path))
            combined_data.to_csv(out_path, sep='\t', index=False)

        elif build_contents_dict[key]['type'] == 'report':
            print('Merging the following files:\n\t{}'.format('\n\t'.join(fps)))
            combined_data = pd.concat([pd.read_csv(fp) for fp in fps]).reset_index(drop=True)

            out_path = os.path.join(out,'{}_{}.csv'.format(build_name,key))
            print("Writing file to: \n\t{}".format(out_path))
            combined_data.to_csv(out_path, index=False)

        elif build_contents_dict[key]['type'] == 'key':
            print('Merging the following files:\n\t{}'.format('\n\t'.join(fps)))
            key_list = [pd.read_csv(fp) for fp in fps]
            df = key_list.pop()
            for other_df in key_list:
                df = df.merge(other_df, how='outer', on=list(other_df.columns)) #this avoids duplicate rows

            out_path = os.path.join(out,'{}_{}.csv'.format(build_name,key))
            print("Writing file to: \n\t{}".format(out_path))
            df.to_csv(out_path, index=False)

if __name__ == "__main__":
    args = build_parser().parse_args(sys.argv[1:])\
    level = (logging.DEBUG if args.verbose else logging.INFO)
    logging.basicConfig(level=level)
    logger.info("args:  {}".format(args))
    main(args)

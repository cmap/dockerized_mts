import os
import shutil
import re
import sys
import glob
import logging
import argparse
import pandas as pd
from cmapPy.pandasGEXpress.parse import parse

logger = logging.getLogger('deal')

build_contents_dict = {
    'inst_info' : {
        'search_pattern': '*_inst_info.txt',
        'type':'metadata',
        'format': 'tsv'
    },
    'cell_info' : {
        'search_pattern': '*_cell_info.txt',
        'type':'metadata',
        'format': 'tsv'
    },
    'QC_TABLE' : {
        'search_pattern': '*QC_TABLE*.csv',
        'type': 'report',
        'format': 'csv'
    },
    'compound_key' : {
        'search_pattern': '*compound_key.csv',
        'type': 'key',
        'format': 'csv'
    },
    'LEVEL2_COUNT': {
        'search_pattern': '*_LEVEL2_COUNT*.csv',
        'type':'data',
        'annotated': False,
        'format': 'csv',
    },
    'LEVEL2_MFI': {
        'search_pattern': '*_LEVEL2_MFI*.csv',
        'type':'data',
        'annotated': False,
        'format': 'csv'
    },
    'LEVEL3_LMFI': {
        'search_pattern': '*_LEVEL3_LMFI*.csv',
        'type':'data',
        'annotated': True,
        'format': 'csv'
    },
    'LEVEL4_LFC': {
        'search_pattern': '*_LEVEL4_LFC_n*.csv',
        'type':'data',
        'annotated': True,
        'format': 'csv'
    },
    'LEVEL4_LFC_COMBAT': {
        'search_pattern': '*_LEVEL4_LFC_COMBAT*.csv',
        'type':'data',
        'annotated': True,
        'format': 'csv'
    },
    'LEVEL5_LFC': {
        'search_pattern': '*_LEVEL5_LFC_n*.csv',
        'type':'data',
        'annotated': True,
        'format': 'csv'
    },
    'LEVEL5_LFC_COMBAT': {
        'search_pattern': '*_LEVEL5_LFC_COMBAT*.csv',
        'type':'data',
        'annotated': True,
        'format': 'csv'
    },
}


def build_parser():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('--build_path', '-b', help='Build path')
    parser.add_argument('--only_key', '-k', help='key to extract. Useful if parallelizing, only listed keys will be concatenated')
    parser.add_argument('--project', '-p', help='Project to extract')
    parser.add_argument('--sig_id_cols', '-s',
        help='Comma separated list of col names to create sig_ids if not present',
        default='pert_plate,culture,pert_id,pert_idose,pert_time',
        )
    #parser.add_argument('--ignore_missing', action="store_true", default=False)
    parser.add_argument('--out', '-o', help='Output for collated build')
    parser.add_argument("--verbose", '-v', help="Whether to print a bunch of output", action="store_true", default=False)

    return parser

"""
Make sig_ids based on id_cols.
"""
def make_sig_id(level5_table, id_cols):
    col_hds = id_cols.split(',')
    level5_table['sig_id'] = level5_table.apply(lambda row: '_'.join([str(row[col]) for col in col_hds]), axis=1)
    return level5_table

"""
    Extract project data and write to file
"""
def slice_and_write_project(data, data_level, project, outpath, args):
    print(project)
    proj_dir = os.path.join(outpath, project, 'data')
    if not os.path.exists(proj_dir):
        os.makedirs(proj_dir)

    if ("LEVEL5" in data_level) & ('sig_id' not in data.columns):
        logger.debug("Generating sig_ids from sig_id_cols arg: {}".format(args.sig_id_cols))
        data = make_sig_id(data, args.sig_id_cols)

    if not build_contents_dict[data_level]['annotated']: #Only used for level 2
        assert len(glob.glob(os.path.join(args.build_path, build_contents_dict['inst_info']['search_pattern']))) == 1, "Incorrect number of inst_info files found"
        inst = pd.read_csv(
            glob.glob(os.path.join(args.build_path, build_contents_dict['inst_info']['search_pattern']))[0],
            sep='\t'
        )

        proj_inst =  inst.loc[
            inst['x_project_id'] == project
        ]

        proj_data =  data.loc[
            data['cid'].isin(proj_inst['profile_id'].unique())
        ]

        nc = len(proj_data['cid'].unique())
        nr = len(proj_data['rid'].unique())
    else:
        proj_data =  data.loc[
            data['x_project_id'] == project
        ]

        col_id = ('profile_id' if 'profile_id' in data.columns else 'sig_id')
        row_id = 'ccle_name'

        nc = len(proj_data[col_id].unique())
        nr = len(proj_data[row_id].unique())

    proj_data.to_csv(
        os.path.join(proj_dir, '{}_{}_n{}x{}.csv'.format(project, data_level, nc, nr)),
        index=False,
    )

def main(args):
    build_path = args.build_path
    outpath = args.out

    if args.only_key and args.project:
        key = args.only_key
        project  = args.project
        dl_dict  = build_contents_dict[key]
        proj_dir = os.path.join(outpath, project, 'data')
        if key == 'inst_info':
            inst = pd.read_csv(glob.glob(os.path.join(build_path, dl_dict['search_pattern']))[0], sep='\t')
            inst.loc[inst['x_project_id'] == project].to_csv(
                os.path.join(proj_dir,'{}_{}.txt'.format(project, key))
            )
        elif key ==  'cell_info':
            shutil.copy(
                glob.glob(os.path.join(build_path, dl_dict['search_pattern']))[0],
                os.path.join(proj_dir,'{}_cell_info.txt'.format(project))
            )
        elif key == 'QC_TABLE':
            inst = pd.read_csv(
                glob.glob(os.path.join(build_path, build_contents_dict['inst_info']['search_pattern']))[0],
                sep='\t'
            )
            proj_inst = inst.loc[inst['x_project_id'] == project]
            preps =  proj_inst.prism_replicate.unique()

            qc = pd.read_csv(glob.glob(os.path.join(build_path, dl_dict['search_pattern']))[0])
            qc.loc[qc['prism_replicate'].isin(preps)].to_csv(os.path.join(proj_dir,'{}_{}.csv'.format(project, key)))
        else:
            data = pd.read_csv(glob.glob(os.path.join(build_path, dl_dict['search_pattern']))[0])
            slice_and_write_project(data, key, project, outpath, args)

    else:
        assert len(glob.glob(os.path.join(build_path, build_contents_dict['inst_info']['search_pattern']))) == 1, "Incorrect number of inst_info files found"

        inst = pd.read_csv(
            glob.glob(os.path.join(build_path,build_contents_dict['inst_info']['search_pattern']))[0],
            sep='\t'
        )
        qc = pd.read_csv(
            glob.glob(os.path.join(build_path,build_contents_dict['QC_TABLE']['search_pattern']))[0],
        )
        for project in inst['x_project_id'].unique():
            if pd.isna(project):
                continue
            proj_dir = os.path.join(outpath, project,'data')

            if not os.path.exists(os.path.join(outpath, project,'data')):
                os.makedirs(os.path.join(outpath, project,'data'))

            proj_inst = inst.loc[
                inst['x_project_id'] == project
            ]

            proj_pp_list = proj_inst['prism_replicate'].unique()
            proj_qc = qc.loc[
                qc['prism_replicate'].isin(proj_pp_list)
            ]

            proj_inst.to_csv(os.path.join(proj_dir,'{}_inst_info.csv'.format(project)),
                            index=False)
            shutil.copy(
                glob.glob(os.path.join(build_path, build_contents_dict['cell_info']['search_pattern']))[0],
                os.path.join(proj_dir,'{}_cell_info.txt'.format(project))
            )
            proj_qc.to_csv(os.path.join(proj_dir, '{}_QC_TABLE.csv'.format(project)),
                          index=False)

        data_files = {k:v for k,v in build_contents_dict.items() if v['type'] == 'data'}

        for data_level, dl_dict in data_files.items():
            print(data_level)
            assert len(glob.glob(os.path.join(build_path, dl_dict['search_pattern']))) == 1, "Incorrect number of files for data level: {}".format(data_level)

            print(glob.glob(os.path.join(build_path, dl_dict['search_pattern']))[0])
            data = pd.read_csv(glob.glob(os.path.join(build_path, dl_dict['search_pattern']))[0])
            for project in inst['x_project_id'].unique():
                if pd.isna(project):
                    continue

                if dl_dict['annotated']:
                    slice_and_write_project(data, data_level, project, outpath, args)
                else:
                    slice_and_write_project(data, data_level, project, outpath, args)

if __name__ == "__main__":
    args = build_parser().parse_args(sys.argv[1:])

    level = (logging.DEBUG if args.verbose else logging.INFO)
    logging.basicConfig(level=level)
    logger.info("args:  {}".format(args))

    main(args)

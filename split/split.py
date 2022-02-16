import os
import re
import sys
import glob
import logging
import argparse
import pandas as pd
import json
# from cmapPy.pandasGEXpress.parse import parse

logger = logging.getLogger('split')

def build_parser():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('--build_path', '-b', help='Build path', required=True)
    parser.add_argument('--project', '-pr', help='Project name')
    parser.add_argument('--pert', '-p', help='Pert ID')
    parser.add_argument('--pert_plate', '-pp', help='Pert plate')
    parser.add_argument('--sig_id_cols', '-s',
        help='Comma separated list of col names to create sig_ids if not present',
        default='pert_plate,culture,pert_id,pert_idose,pert_time',
        )
    parser.add_argument('--out', '-o', help='Output for project level folders', required=True)
    parser.add_argument("--verbose", '-v', help="Whether to print a bunch of output", action="store_true", default=False)

    return parser

"""
Make sig_ids based on id_cols.
"""
def make_sig_id(level5_table, id_cols):
    col_hds = id_cols.split(',')
    level5_table['sig_id'] = level5_table.apply(lambda row: '_'.join([str(row[col]) for col in col_hds]), axis=1)
    return level5_table


def write_csv_with_dim(data, outpath, filename):
    if not os.path.exists(outpath):
        os.makedirs(outpath)

    col_id = ('profile_id' if 'profile_id' in data.columns else 'sig_id')
    row_id = ('rid' if 'rid' in data.columns else 'ccle_name')
    nprofiles =  len(data[col_id].unique())
    ncell_lines = len(data[row_id].unique())

    out_file = os.path.join(outpath, '{}_n{}x{}.csv'.format(filename,nprofiles,ncell_lines))
    logger.debug("Writing csv to {}".format(out_file))
    data.to_csv(out_file, index=False)

def make_compound_slice(data, out, project, pert_plate, pert, outfile_prefix):
    logger.debug("project: {}, pert_plate: {} pert:{}".format(project, pert_plate, pert))

    pert_data = data.loc[
        (data['x_project_id'] == project) &
        (data['pert_plate'] == pert_plate) &
        (data['pert_id'] == pert)
    ]

    assert len(pert_data) > 0, "No matches found, using pert_ids?"

    pert_clean = re.sub('[^0-9a-zA-Z\-\_]+', '', pert.replace('|', '_')) #filenames should not contain '|'
    pert_outdir = os.path.join(out, project,pert_plate, pert_clean.upper())

    write_csv_with_dim(
        data = pert_data.loc[pert_data.pert_plate.eq(pert_plate)],
        outpath = pert_outdir,
        filename = '{}_{}'.format(outfile_prefix, pert_clean)
    )

def read_build_file(search_pattern, args):
    fstr = os.path.join(args.build_path, search_pattern)
    fmatch = glob.glob(fstr)
    assert (len(fmatch) == 1) , "Too many files found: {}".format(fmatch)
    return pd.read_csv(fmatch[0])

def main(args):
    try:
        fstr = os.path.join(args.build_path, '*LEVEL4_LFC_COMBAT*')
        fmatch = glob.glob(fstr)
        assert (len(fmatch) == 1) , "Too many files found"
        level4 = read_build_file('*LEVEL4_LFC_COMBAT*.csv', args)
        level5 = read_build_file('*LEVEL5_LFC_COMBAT*.csv', args)

        if 'sig_id' not in level5.columns:
            level5 = make_sig_id(level5, args.sig_id_cols)

    except IndexError as err:
        logger.error(err)
        logger.error("Index Error: No file found Check --build_path arg")
        raise

    out = args.out

    if all([args.pert, args.pert_plate, args.project]):
        make_compound_slice(
            data=level4,
            out = args.out,
            project = args.project,
            pert_plate = args.pert_plate,
            pert = args.pert,
            outfile_prefix = 'LEVEL4_LFC_COMBAT'
        )

        make_compound_slice(
            data=level5,
            out = args.out,
            project = args.project,
            pert_plate = args.pert_plate,
            pert = args.pert,
            outfile_prefix = 'LEVEL5_LFC_COMBAT'
        )

    else:
        #compound_key = pd.read_csv(glob.glob(os.path.join(args.build_path, '*compound_key.csv'))[0])
        logger.debug("Projects: {}".format( level4.x_project_id.unique()))
        for project in level4.x_project_id.unique():
            logger.debug(project)

            project_data = level4.loc[
                level4['x_project_id'] == project
            ]

            logger.debug("Project data size: {}".format(len(project_data)))

            project_perts = project_data['pert_id'].unique()

            logger.info("\nPROJECT: {} \nPROJECT PERT_IDS: {}\n".format(project, list(project_perts)))
            for pert in project_perts:
                logger.debug(pert)
                for pert_plate in project_data[project_data['pert_id'] == pert].pert_plate.unique():
                    make_compound_slice(
                        data = project_data,
                        out = args.out,
                        project = project,
                        pert_plate = pert_plate,
                        pert = pert,
                        outfile_prefix = 'LEVEL4_LFC_COMBAT'
                    )
                    make_compound_slice(
                        data=level5,
                        out = args.out,
                        project = project,
                        pert_plate = pert_plate,
                        pert = pert,
                        outfile_prefix = 'LEVEL5_LFC_COMBAT'
                    )




if __name__ == "__main__":
    args = build_parser().parse_args(sys.argv[1:])

    level = (logging.DEBUG if args.verbose else logging.INFO)
    logging.basicConfig(level=level)
    logger.info("args:  {}".format(args))

    main(args)

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
    parser.add_argument('--pert', '-p', help='Pert name')
    parser.add_argument('--pert_plate', '-pp', help='Pert plate')
    parser.add_argument('--out', '-o', help='Output for project level folders', required=True)
    parser.add_argument("--verbose", '-v', help="Whether to print a bunch of output", action="store_true", default=False)

    return parser

def write_csv_with_dim(data, outpath, filename):
    if not os.path.exists(outpath):
        os.makedirs(outpath)

    nprofiles =  len(data['profile_id'].unique())
    ncell_lines = len(data['rid'].unique())

    out_file = os.path.join(outpath, '{}_n{}x{}.csv'.format(filename,nprofiles,ncell_lines))
    logger.debug("Writing csv to {}".format(out_file))
    data.to_csv(out_file, index=False)


def make_compound_slice(data, out, project, pert_plate, pert):

    pert_data = data.loc[
        (data['x_project_id'] == project) &
        (data['pert_plate'] == pert_plate) &
        (data['pert_iname'] == pert)
    ]

    pert_clean = pert.replace('|', '_') #filenames should not contain '|'
    pert_outdir = os.path.join(out, project,pert_plate, pert_clean)

    write_csv_with_dim(
        data = pert_data.loc[pert_data.pert_plate.eq(pert_plate)],
        outpath = pert_outdir,
        filename = 'LEVEL4_LFC_{}'.format(pert_clean)
    )



def main(args):
    try:
        fstr = os.path.join(args.build_path, '*LEVEL4_LFC_COMBAT*')
        fmatch = glob.glob(fstr)
        assert (len(fmatch) == 1) , "Too many files found"
        level4 = pd.read_csv(fmatch[0])
    except IndexError as err:
        logger.error(err)
        logger.error("Index Error: No file found Check --build_path arg")
        raise

    out = args.out
    #read the environment variables for AWS Batch if any
    #AWS_BATCH_JOB_ARRAY_INDEX - a special index set by AWS
    #PROJECT_KEYS - list of project keys as a JSON string
    project_keys = os.getenv('PROJECT_KEYS')
    aws_batch_index = os.getenv('AWS_BATCH_JOB_ARRAY_INDEX')
    if all([project_keys,aws_batch_index]):
        project_keys  = json.loads(project_keys)
        project_key = project_keys[int(aws_batch_index)]
        args.pert = project_key["pert_iname"]
        args.project = project_key["x_project_id"]
        args.pert_plate = project_key["pert_plate"]
        print(args)

    if all([args.pert, args.pert_plate, args.project]):
        make_compound_slice(
            data=level4,
            out = args.out,
            project = args.project,
            pert_plate = args.pert_plate,
            pert = args.pert
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

            project_perts = project_data['pert_iname'].unique()

            logger.info("\nPROJECT: {} \nPROJECT PERT_INAMES: {}\n".format(project, list(project_perts)))
            for pert in project_perts:
                logger.debug(pert)
                for pert_plate in project_data[project_data['pert_iname'] == pert].pert_plate.unique():
                    make_compound_slice(
                        data = project_data,
                        out = args.out,
                        project = project,
                        pert_plate = pert_plate,
                        pert = pert
                    )




if __name__ == "__main__":
    args = build_parser().parse_args(sys.argv[1:])

    level = (logging.DEBUG if args.verbose else logging.INFO)
    logging.basicConfig(level=level)
    logger.info("args:  {}".format(args))

    main(args)

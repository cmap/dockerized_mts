import os
import re
import sys
import glob
import logging
import argparse
import pandas as pd
# from cmapPy.pandasGEXpress.parse import parse

logger = logging.getLogger('split')

def build_parser():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('--build_path', '-b', help='Build path', required=True)
    # parser.add_argument('--compound_key', '-k', help='compound_key file')
    # parser.add_argument('--level4_filename', '-d', help='Level4 annotated CSV')
    parser.add_argument('--out', '-o', help='Output for project level folders', required=True)
    parser.add_argument("--verbose", '-v', help="Whether to print a bunch of output", action="store_true", default=False)

    return parser


def main(args):
    out = args.out
    compound_key = pd.read_csv(glob.glob(os.path.join(args.build_path, '*compound_key.csv'))[0])
    #compound_key = pd.read_csv(glob.glob(os.path.join(args.build_path, '*compound_key.csv'))[0])
    level4 = pd.read_csv(glob.glob(os.path.join(args.build_path, '*LEVEL4_LFC*'))[0])
    #compound_key = pd.read_csv('compound_key.csv')

    for project in compound_key.x_project_id.unique():
        logger.debug(project)
        project_outdir = os.path.join(out, project)
        if not os.path.exists(project_outdir):
            os.makedirs(project_outdir)

        project_perts = compound_key.loc[
            compound_key.x_project_id.eq(project)
        ]['pert_iname'].unique()

        project_data = level4[
            level4['pert_iname'].isin(project_perts)  &
            (level4['x_project_id'] == project)
        ]

        project_data.to_csv(
            os.path.join(project_outdir, '{}_LEVEL4_LFC_n{}x{}.csv'.format(
                project,
                len(project_data['profile_id'].unique()),
                len(project_data['rid'].unique())
                )
            ),
            index=False
        )

        logger.info("\nPROJECT: {} \nPROJECT PERT_INAMES: {}\n".format(project, list(project_perts)))
        for pert in project_perts:
            logger.debug(pert)
            pert_clean = pert.replace('|', '_') #filenames should not contain '|'
            pert_outdir = os.path.join(out, project,pert_clean)

            logger.debug(pert_outdir)
            if not os.path.exists(pert_outdir):
                os.makedirs(pert_outdir)

            pert_data = project_data.loc[
                project_data['pert_iname'] == pert
            ]

            nprofiles =  len(pert_data['profile_id'].unique())
            ncell_lines = len(pert_data['rid'].unique())

            pert_data.to_csv(
                os.path.join(pert_outdir, '{}_LEVEL4_LFC_n{}x{}.csv'.format(pert_clean, nprofiles, ncell_lines)),
                index=False
            )


if __name__ == "__main__":
    args = build_parser().parse_args(sys.argv[1:])

    level = (logging.DEBUG if args.verbose else logging.INFO)
    logging.basicConfig(level=level)
    logger.info("args:  {}".format(args))

    main(args)

import logging
import pandas as pd
import os
import src.flagging_functions as ff
import argparse
import glob
import setup_logger as setup_logger

logger = logging.getLogger(setup_logger.LOGGER_NAME)


def build_parser():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('--build_path', '-b', help='Build path', required=True)
    parser.add_argument('--thresholds', '-t', help='QC thresholds to use',
                        default=None)
    parser.add_argument('--name', '-n', default='', help='Build name.')
    parser.add_argument("--verbose", '-v', help="Whether to print a bunch of output", action="store_true",
                        default=False)

    return parser


def main(args):
    build_path = args.build_path
    build_name = args.name
    thresholds = args.thresholds  # NEED TO UPDATE THIS TO PARSE INTO DICT

    if build_path:
        mfi = pd.read_csv(glob.glob(os.path.join(build_path, '*LEVEL3_LMFI*'))[0])
        qc_table = pd.read_csv(glob.glob(os.path.join(build_path, '*QC_TABLE*'))[0])

        qc_flag_table = ff.generate_flag_df(mfi=mfi,
                                            qc_table=qc_table,
                                            thresholds=thresholds)

        qc_flag_table.to_csv(build_path + '/{}_QC_FLAG_TABLE.csv'.format(build_name))


if __name__ == "__main__":
    args = build_parser().parse_args()
    level = (logging.DEBUG if args.verbose else logging.INFO)
    logging.basicConfig(level=level)
    logger.info("args: {}".format(args))

    main(args)

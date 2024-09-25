import os
import re
import sys
import glob
import logging
import argparse
import pandas as pd
import json

# from cmapPy.pandasGEXpress.parse import parse

logger = logging.getLogger("split")


def build_parser():
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument("--build_path", "-b", help="Build path", required=True)
    parser.add_argument("--project", "-pr", help="Project name", required=True)
    parser.add_argument("--pert", "-p", help="Pert ID", required=True)
    parser.add_argument("--pert_plate", "-pp", help="Pert plate", required=True)
    parser.add_argument(
        "--search_patterns",
        "-sp",
        help="Comma separated list of search patterns",
        default="LEVEL3_LMFI,LEVEL4_LFC_COMBAT,LEVEL5_LFC_COMBAT",
    )
    parser.add_argument(
        "--out", "-o", help="Output for project level folders", required=True
    )
    parser.add_argument(
        "--verbose",
        "-v",
        help="Whether to print a bunch of output",
        action="store_true",
        default=False,
    )

    return parser


def write_csv_with_dim(data, outpath, filename):
    if not os.path.exists(outpath):
        os.makedirs(outpath)

    col_id = "profile_id" if "profile_id" in data.columns else "sig_id"
    row_id = "rid" if "rid" in data.columns else "ccle_name"
    nprofiles = len(data[col_id].unique())
    ncell_lines = len(data[row_id].unique())

    out_file = os.path.join(
        outpath, "{}_n{}x{}.csv".format(filename, nprofiles, ncell_lines)
    )
    logger.debug("Writing csv to {}".format(out_file))
    data.to_csv(out_file, index=False)


def make_compound_slice_for_pattern(pattern, project, pert_plate, pert, build_path, out):
    """
    Make a slice of the data based on project, pert_plate, and pert.
    """
    data_chunks = read_build_file_in_chunks(pattern, build_path, chunksize=10000)  # returns chunk generator

    # process chunks
    compound_df = pd.DataFrame()
    for chunk in data_chunks:
        filtered_chunk = chunk.loc[
            (chunk["x_project_id"] == project)
            & (chunk["pert_plate"] == pert_plate)
            & (chunk["pert_id"] == pert)
            ]
        compound_df = pd.concat([compound_df, filtered_chunk])

    assert len(compound_df) > 0, "No matches found, using pert_ids?"

    pert_clean = re.sub(
        "[^0-9a-zA-Z\-\_\.]+", "", pert.replace("|", "_")
    )  # filenames should not contain '|'
    pert_outdir = os.path.join(out, project, pert_plate, pert_clean.upper())

    write_csv_with_dim(
        data=compound_df,
        outpath=pert_outdir,
        filename="{}_{}".format(pattern, pert_clean),
    )


def read_build_file_in_chunks(search_pattern, build_path, chunksize=1000):
    fstr = os.path.join(build_path, "*" + search_pattern + "*")
    fmatch = glob.glob(fstr)
    assert len(fmatch) == 1, "Incorrect number of files found: {}".format(fmatch)
    return pd.read_csv(fmatch[0], chunksize=chunksize)


def main(args):
    patterns = args.search_patterns.split(",")
    for pattern in patterns:
        make_compound_slice_for_pattern(pattern,
                                        args.project,
                                        args.pert_plate,
                                        args.pert,
                                        args.build_path,
                                        args.out)

if __name__ == "__main__":
    args = build_parser().parse_args(sys.argv[1:])
    level = logging.DEBUG if args.verbose else logging.INFO
    logging.basicConfig(level=level)
    logger.info("args:  {}".format(args))

    main(args)
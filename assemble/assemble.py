"""

Command line script which takes the two CSVs belonging to a single PRISM replicate and combines them into a GCT file
along with all of the relevant meta data.

The meta data inputs are a plate map, a cell set definition file, a plate tracking file, and a davepool-analyte mapping.
"""
import os
import sys
import ast
import json
import yaml
import logging
import argparse
import traceback



import requests
import configparser
from urllib.request import urlopen

import setup_logger as setup_logger
import utils.exceptions as assemble_exception
import utils.path_utils as path_utils

import davepool_data as davepool_data
import prism_metadata as prism_metadata
import assemble_core as assemble_core


logger = logging.getLogger(setup_logger.LOGGER_NAME)

_prism_cell_config_file_section = "PrismCell column headers"
_davepool_analyte_mapping_file_section = "DavepoolAnalyteMapping column headers"

pert_column_metadata_fields = ['pert_id', 'pert_dose', 'pert_type', 'pert_well', 'pert_dose_unit',
                          'pert_iname']
prismcell_row_metadata_fields = ['ccle_name', 'davepool_id', 'analyte_id', 'barcode_id', 'cell_iname', 'pool_id']

API_URL = 'https://api.clue.io/api/'
DEV_API_URL = 'https://dev-api.clue.io/api/'
API_KEY = os.environ['API_KEY']
default_config_filepath = "https://s3.amazonaws.com/analysis.clue.io/vdb/merino/prism_pipeline.cfg"

def build_parser():

    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    # The following arguments are required. These are files that are necessary for assembly and which change
    # frequently between cohorts, replicates, etc.
    parser.add_argument("-config_filepath", "-cfg", help="path to the location of the configuration file", type=str,
                        default=default_config_filepath)
    parser.add_argument("-csv_filepath", "-csv", help="full path to csv", type=str,  required=True)
    parser.add_argument("-assay_type", "-at", help="assay data was profiled in",
                        type=str, required=False)
    parser.add_argument("-plate_map_path", "-pmp",
                        help="path to file containing plate map describing perturbagens used", type=str, required=False)
    parser.add_argument("-map_src_plate", "-map",
                        help="Pert Plate with replicate map name. Searches database, using API KEY environment variable",
                        type=str, required=False)

    # These arguments are optional. Some may be superfluous now and might be removed.
    parser.add_argument("-verbose", '-v', help="Whether to print a bunch of output", action="store_true", default=False)
    parser.add_argument("--dev", help=argparse.SUPPRESS, action="store_true", default=False)

    parser.add_argument("-cell_set_definition_file", "-csdf",
                        help="file containing cell set definition to use, overriding config file",
                        type=str, default=None, required=False)
    parser.add_argument("-outfile", "-out", help="location to write gct", type=str,
                        default='')
    parser.add_argument("-truncate_to_plate_map", "-trunc", help="True or false, if true truncate data to fit framework of platemap provided",
                        action="store_true", default=True)

    return parser

def write_args_to_file(args, outfile):
    with open(outfile, "w") as f:
        print(vars(args))
        yaml.dump(vars(args), f)

def read_csv(csv_filepath, assay_type):

    pd = davepool_data.read_data(csv_filepath)
    pd.davepool_id = assay_type
    return pd

'''
There are some cases in which we are subsetting plates into different groups, ie. more than one gct per plate.
This was the case for PPCN. As such, we need a function to truncate the data to match the plate map which is given.
:param davepool_data_objects:
:param all_perturbagens:
:param truncate_to_platemap:
:return:
'''
def truncate_data_objects_to_plate_map(davepool_data_objects, all_perturbagens, truncate_to_platemap):
    platemap_well_list = set([p.pert_well for p in all_perturbagens])
    for davepool in davepool_data_objects:
        if platemap_well_list == set(davepool.median_data.keys()):
            return davepool_data_objects
        elif truncate_to_platemap == True:
            for d in list(davepool_data_objects[0].median_data):
                 if d not in platemap_well_list:
                     del davepool_data_objects[0].median_data[d]

            for c in list(davepool_data_objects[0].count_data):
                if c not in platemap_well_list:
                    del davepool_data_objects[0].count_data[c]

        else:
            msg = "Assemble truncate data objects to plate map: Well lists of platemap and csv do not match"
            raise assemble_exception.DataMappingMismatch(msg)

    return davepool_data_objects

def main(args, all_perturbagens=None, assay_plates=None):

    prism_replicate_name = os.path.basename(args.csv_filepath).rsplit(".", 1)[0]
    (_, assay, tp, replicate_number, bead) = prism_replicate_name.rsplit("_")

    if bead is not None and args.assay_type is None:
        api_call = os.path.join('https://api.clue.io/api', 'beadset', bead)
        db_entry = requests.get(api_call)
        args.assay_type = json.loads(db_entry.text)['assay_variant']

    if args.assay_type == None:
        msg = "No assay type found from beadset - must be specified in arg -assay_type"
        raise assemble_exception.NoAssayTypeFound(msg)


    davepool_id_csv_list = args.csv_filepath
    davepool_data_objects = [read_csv(davepool_id_csv_list, args.assay_type)]

    # Set up output directory
    if not os.path.exists(os.path.join(args.outfile, "assemble", prism_replicate_name)):
        os.makedirs(os.path.join(args.outfile, "assemble", prism_replicate_name))

    # Write args used to yaml file
    write_args_to_file(args, os.path.join(args.outfile, "assemble", prism_replicate_name, 'config.yaml'))

    #Select API
    api_url = DEV_API_URL if args.dev else API_URL

    if args.map_src_plate is not None:
        all_perturbagens = prism_metadata.build_perturbagens_from_db(args.map_src_plate, tp, api_url=api_url) # Read from DB
    elif args.plate_map_path is not None:
        all_perturbagens = prism_metadata.build_perturbagens_from_file(args.plate_map_path, tp)
    else:
        raise ValueError("One of -plate_map_path or -map_src_plate is required")

    for pert in all_perturbagens:
        pert.validate_properties(pert_column_metadata_fields)

    #read actual data from relevant csv files, associate it with davepool ID
    prism_cell_list = prism_metadata.build_prism_cell_list_from_db(args.assay_type, api_url=api_url)

    #prism_cell_list = prism_metadata.build_prism_cell_list(cp, cell_set_file)

    logger.info("len(prism_cell_list):  {}".format(len(prism_cell_list)))

    #expected_prism_cell_metadata_fields = prismcell_row_metadata_fields
    for cell in prism_cell_list:
        cell.validate_properties(prismcell_row_metadata_fields)

    # truncate csv to plate map size if indicated by args.truncate_to_plate_map
    truncate_data_objects_to_plate_map(davepool_data_objects, all_perturbagens, args.truncate_to_plate_map)

    # Pass python objects to the core assembly module (this is where command line and automated assembly intersect)
    # here the outfile for automation is defined as project_dir/prism_replicate_set_name
    try:
        assemble_core.main(prism_replicate_name, args.outfile, all_perturbagens, davepool_data_objects, prism_cell_list)

    except Exception as e:
        failure_path = os.path.join(args.outfile, "assemble", prism_replicate_name,  "failure.txt")
        ex_type, ex, tb = sys.exc_info()
        with open(failure_path, "w") as file:
            file.write("plate {} failed for reason: {}: {}\n".format(prism_replicate_name, ex_type, ex))
            file.write("\ntraceback:\n")
            traceback.print_tb(tb, file=file)
        sys.exit(-1)

    success_path = os.path.join(args.outfile, "assemble", prism_replicate_name, "success.txt")
    with open(success_path, "w") as file:
        file.write("plate {} successfully assembled".format(prism_replicate_name))

if __name__ == "__main__":
    args = build_parser().parse_args(sys.argv[1:])
    setup_logger.setup(verbose=args.verbose)

    logger.info("args:  {}".format(args))

    if not (args.map_src_plate or args.plate_map_path):
        raise ValueError("One of -plate_map_path or -map_src_plate is required")

    main(args)

"""

Command line script which takes the two CSVs belonging to a single PRISM replicate and combines them into a GCT file
along with all of the relevant meta data.

The meta data inputs are a plate map, a cell set definition file, a plate tracking file, and a davepool-analyte mapping.
"""
import os
import sys
import ast
import json
import logging
import argparse
import requests
import ConfigParser
import urllib2

import merino
import merino.setup_logger as setup_logger
import merino.utils.path_utils as path_utils
import merino.utils.exceptions as merino_exception
import merino.misc_tools.config_yaml as cyaml

import davepool_data as davepool_data
import prism_metadata as prism_metadata
import assemble_core as assemble_core


logger = logging.getLogger(setup_logger.LOGGER_NAME)

_prism_cell_config_file_section = "PrismCell column headers"
_davepool_analyte_mapping_file_section = "DavepoolAnalyteMapping column headers"


def build_parser():

    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    # The following arguments are required. These are files that are necessary for assembly and which change
    # frequently between cohorts, replicates, etc.
    parser.add_argument("-config_filepath", "-cfg", help="path to the location of the configuration file", type=str,
                        default=merino.default_config_filepath)
    parser.add_argument("-assay_type", "-at", help="assay data was profiled in",
                        type=str, required=False)
    parser.add_argument("-plate_map_path", "-pmp",
                        help="path to file containing plate map describing perturbagens used", type=str, required=True)

    # These arguments are optional. Some may be superfluous now and might be removed.
    parser.add_argument("-verbose", '-v', help="Whether to print a bunch of output", action="store_true", default=False)

    parser.add_argument("-analyte_mapping_file", "-amf",
                        help="mapping of analytes to pools and davepools, overriding config file",
                        type=str, default=None, required=False)
    parser.add_argument("-cell_set_definition_file", "-csdf",
                        help="file containing cell set definition to use, overriding config file",
                        type=str, default=None, required=False)

    parser.add_argument("-ignore_assay_plate_barcodes", "-batmanify", help="list of assay plate barcodes that should be"
                        " ignored / excluded from the assemble", nargs="+", default=None)
    parser.add_argument("-outfile", "-out", help="location to write gct", type=str,
                        default='')
    parser.add_argument("-truncate_to_plate_map", "-trunc", help="True or false, if true truncate data to fit framework of platemap provided",
                        action="store_true", default=True)
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("-davepool_id_csv_filepath_pairs", "-dp_csv",
                        help="space-separated list of pairs of davepool_id and corresponding csv filepath for that davepool_id",
                        type=str, nargs="+", required=False)
    group.add_argument("-csv_filepath", "-csv", help="full path to csv", type=str,  required=False)

    return parser


def read_davepool_data_objects(davepool_id_csv_list):
    '''
    create davepool objects and populate with data read from csv's
    :param davepool_id_csv_list: list of pairs of davepool ID and path to corresponding csv file for that davepool
    :return:
    '''
    r = []

    for (dp_id, csv_filepath) in davepool_id_csv_list:
        pd = davepool_data.read_data(csv_filepath)
        pd.davepool_id = dp_id
        r.append(pd)

    return r

def read_csv(csv_filepath, assay_type):

    pd = davepool_data.read_data(csv_filepath)
    pd.davepool_id = assay_type
    return pd


def build_davepool_id_csv_list(davepool_id_csv_filepath_pairs):
    '''
    break list of davepool_id and csv file path from input into pairs
    :param davepool_id_csv_filepath_pairs:
    :return:
    '''
    r = []

    for i in range(len(davepool_id_csv_filepath_pairs)/2):
        index = 2*i
        davepool_id = davepool_id_csv_filepath_pairs[index]
        csv_filepath = davepool_id_csv_filepath_pairs[index+1]
        r.append((davepool_id, csv_filepath))

    return r


def build_prism_cell_list(config_parser, cell_set_definition_file, analyte_mapping_file):
    '''
    read PRISM cell line metadata from file specified in config file, then associate with
    assay_plate based on pool ID, pulling out metadata based on config specifications.  Check for cell pools that are not associated with any assay plate
    :param config_parser: parser pre-loaded with config file
    :param cell_set_definition_file:
    :param analyte_mapping_file:
    :return:
    '''

    #read headers to pull from config and convert to tuple format expected by data parser
    prism_cell_list_items = config_parser.get("headers_to_pull", "cell_set_definition_headers")

    prism_cell_list_items = [(x,x) for x in ast.literal_eval(prism_cell_list_items)]
    prism_cell_list = prism_metadata.read_prism_cell_from_file(cell_set_definition_file, prism_cell_list_items)

    analyte_mapping_items = config_parser.get("headers_to_pull", "analyte_mapping_headers")
    analyte_mapping_items = [(x,x) for x in ast.literal_eval(analyte_mapping_items)]
    analyte_mapping = prism_metadata.read_prism_cell_from_file(analyte_mapping_file, analyte_mapping_items)

    cell_list_id_not_in_davepool_mapping = set()

    # Assign davepool mapping info to respective cell feature IDs

    cell_id_davepool_map = {}

    for dp in analyte_mapping:
        cell_id_davepool_map[dp.feature_id] = dp


    for pc in prism_cell_list:
        if pc.feature_id in cell_id_davepool_map.keys():
            cell_davepool = cell_id_davepool_map[pc.feature_id]
            pc.analyte_id = cell_davepool.analyte_id

        else:
            cell_list_id_not_in_davepool_mapping.add(pc.feature_id)

    if len(cell_list_id_not_in_davepool_mapping) > 0:
        cell_list_id_not_in_davepool_mapping = list(cell_list_id_not_in_davepool_mapping)
        cell_list_id_not_in_davepool_mapping.sort()
        msg = ("some cell ids were found in the cell set but not in the davepool mapping - IDs: {}".format(cell_list_id_not_in_davepool_mapping))
        raise merino_exception.DataMappingMismatch(msg)

    return prism_cell_list


def truncate_data_objects_to_plate_map(davepool_data_objects, all_perturbagens, truncate_to_platemap):
    '''
    There are some cases in which we are subsetting plates into different groups, ie. more than one gct per plate.
    This was the case for PPCN. As such, we need a function to truncate the data to match the plate map which is given.
    :param davepool_data_objects:
    :param all_perturbagens:
    :param truncate_to_platemap:
    :return:
    '''
    platemap_well_list = set([p.pert_well for p in all_perturbagens])
    for davepool in davepool_data_objects:
        if platemap_well_list == set(davepool.median_data.keys()):
            return davepool_data_objects
        elif truncate_to_platemap == True:
            for d in davepool_data_objects[0].median_data.keys():
                 if d not in platemap_well_list:
                     del davepool_data_objects[0].median_data[d]

            for c in davepool_data_objects[0].count_data.keys():
                if c not in platemap_well_list:
                    del davepool_data_objects[0].count_data[c]

        else:
            msg = "Assemble truncate data objects to plate map: Well lists of platemap and csv do not match"
            raise merino_exception.DataMappingMismatch(msg)

    return davepool_data_objects

def setup_input_files(args):
    # Check args for over-riding files, i.e. use of -csdf and -amf to override config paths to mapping files
    # or, if not overridden, read PRISM cell line metadata from file specified in config file, and associate with assay_plate metadata

    cp = ConfigParser.ConfigParser()

    if args.config_filepath:
        config_path = path_utils.validate_path_as_uri(args.config_filepath)
        page = urllib2.urlopen(config_path)
        f = open("local.cfg", "w")
        content = page.read()
        f.write(content)
        f.close()
        cp.read('local.cfg')
    else:
        #todo: download from s3 to overwrite local prism_pipeline.cfg
        pass

    cell_set_file_path = args.cell_set_definition_file if args.cell_set_definition_file else cp.get(args.assay_type, "cell_set_definition_file")
    analyte_mapping_file_path = args.analyte_mapping_file if args.analyte_mapping_file else cp.get(args.assay_type, "analyte_mapping_file")

    return (cp, cell_set_file_path, analyte_mapping_file_path)


def main(args, all_perturbagens=None, assay_plates=None):

    if args.davepool_id_csv_filepath_pairs is not None:
        davepool_id_csv_list = build_davepool_id_csv_list(args.davepool_id_csv_filepath_pairs)
        davepool_data_objects = read_davepool_data_objects(davepool_id_csv_list)

        pert_plate = os.path.basename(args.plate_map_path).rsplit(".", 1)[0].split('.')[0]
        prism_replicate_name = os.path.basename(davepool_id_csv_list[0][1]).rsplit(".", 1)[0]
        (_, assay, tp, replicate_number, bead) = prism_replicate_name.rsplit("_")

        if args.assay_type == None:
            msg = "No assay type found from beadset - must be specified in arg -assay_type"
            raise merino_exception.NoAssayTypeFound(msg)

    elif args.csv_filepath is not None:

        pert_plate = os.path.basename(args.plate_map_path).rsplit(".", 1)[0].split('.')[0]
        prism_replicate_name = os.path.basename(args.csv_filepath).rsplit(".", 1)[0]
        (_, assay, tp, replicate_number, bead) = prism_replicate_name.rsplit("_")

        if bead is not None and args.assay_type is None:
            api_call = os.path.join('https://api.clue.io/api', 'beadset', bead)
            db_entry = requests.get(api_call)
            args.assay_type = json.loads(db_entry.text)['assay_variant']

        if args.assay_type == None:
            msg = "No assay type found from beadset - must be specified in arg -assay_type"
            raise merino_exception.NoAssayTypeFound(msg)


        davepool_id_csv_list = args.csv_filepath
        davepool_data_objects = []
        davepool_data_objects.append(read_csv(davepool_id_csv_list, args.assay_type))



    # Set up output directory
    if not os.path.exists(os.path.join(args.outfile, "assemble", prism_replicate_name)):
        os.makedirs(os.path.join(args.outfile, "assemble", prism_replicate_name))

    # Write args used to yaml file
    cyaml.write_args_to_file(args, os.path.join(args.outfile, "assemble", prism_replicate_name, 'config.yaml'))

    (cp, cell_set_file, analyte_mapping_file) = setup_input_files(args)

    if all_perturbagens is None:
        all_perturbagens = prism_metadata.build_perturbagens_from_file(args.plate_map_path, tp)

    for pert in all_perturbagens:
        pert.validate_properties(ast.literal_eval(cp.get("required_metadata_fields", "column_metadata_fields")))

    args.ignore_assay_plate_barcodes = set(args.ignore_assay_plate_barcodes) if args.ignore_assay_plate_barcodes is not None else set()

    #read actual data from relevant csv files, associate it with davepool ID


    prism_cell_list = build_prism_cell_list(cp, cell_set_file, analyte_mapping_file)

    logger.info("len(prism_cell_list):  {}".format(len(prism_cell_list)))

    expected_prism_cell_metadata_fields = ast.literal_eval(cp.get("required_metadata_fields","row_metadata_fields"))
    for cell in prism_cell_list:
        cell.validate_properties(expected_prism_cell_metadata_fields)

    # truncate csv to plate map size if indicated by args.truncate_to_plate_map
    truncate_data_objects_to_plate_map(davepool_data_objects, all_perturbagens, args.truncate_to_plate_map)

    # Pass python objects to the core assembly module (this is where command line and automated assembly intersect)
    # here the outfile for automation is defined as project_dir/prism_replicate_set_name

    try:
        assemble_core.main(prism_replicate_name, args.outfile, all_perturbagens, davepool_data_objects, prism_cell_list)



    except Exception as e:
        failure_path = os.path.join(args.outfile, "assemble", prism_replicate_name,  "failure.txt")
        with open(failure_path, "w") as file:
            file.write("plate {} failed for reason {}".format(prism_replicate_name, e))
        return

    success_path = os.path.join(args.outfile, "assemble", prism_replicate_name, "success.txt")
    with open(success_path, "w") as file:
        file.write("plate {} successfully assembled".format(prism_replicate_name))

if __name__ == "__main__":
    args = build_parser().parse_args(sys.argv[1:])
    setup_logger.setup(verbose=args.verbose)

    logger.info("args:  {}".format(args))

    main(args)

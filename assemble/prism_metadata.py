import merino.setup_logger as setup_logger
import os
import ast
import pandas
import logging
import requests
import parse_data

logger = logging.getLogger(setup_logger.LOGGER_NAME)

API_URL = 'https://api.clue.io/api/'
API_KEY = os.environ['API_KEY']

CELL_SET_DEFINITION_HEADERS = [
    'analyte_id',
    'pool_id',
    'davepool_id',
    'feature_id',
    'cell_iname',
    'ccle_name',
    'cell_lineage',
    'cell_culture',
    'barcode_id'
]

class PrismCell(object):
    def __init__(self, pool_id=None, analyte_id=None, davepool_id=None, feature_id=None):
        self.pool_id = pool_id
        self.analyte_id = analyte_id
        self.davepool_id = davepool_id
        self.feature_id = feature_id

        self.ignore = False

    def __repr__(self):
        return " ".join(["{}:{}".format(str(k),str(v)) for (k,v) in self.__dict__.items()])

    def __str__(self):
        return self.__repr__()

    def validate_properties(self, expected_properties):
        for property in expected_properties:
            if hasattr(self,property):
                continue
            else:
                raise Exception("missing property: {}".format(property))


class Perturbagen(object):
    def __init__(self, pert_well=None):
        self.pert_well = pert_well

    def __repr__(self):
        return " ".join(["{}:{}".format(str(k),str(v)) for (k,v) in self.__dict__.items()])

    def __str__(self):
        return self.__repr__()

    def validate_properties(self, expected_properties):
        for property in expected_properties:
            if hasattr(self,property):
                continue
            else:
                raise Exception("missing property: {}".format(property))


def make_request_url_filter(endpoint_url, where=None, fields=None):
    clauses = []
    if where:
        where_clause = '"where":{'
        wheres = []
        for k,v in where.items():
            wheres.append('"{k}":"{v}"'.format(k=k, v=v))
        where_clause += ','.join(wheres) + '}'
        clauses.append(where_clause)

    if fields:
        fields_clause = '"fields":{'
        fields_list = []
        if type(fields) == dict:
            for k, v in fields.items():
                fields_list.append('"{k}":"{v}"'.format(k=k, v=v))
        elif type(fields) == list:
            for field in fields:
                fields_list.append('"{k}":"{v}"'.format(k=field, v="true"))
        fields_clause += ','.join(fields_list) + '}'
        clauses.append(fields_clause)

    if len(clauses) > 0:
        #print(endpoint_url.rstrip("/") + '?filter={' +  ','.join(clauses) + '}')
        return endpoint_url.rstrip("/") + '?filter={' +  requests.utils.quote(','.join(clauses)) + '}'
    else:
        return endpoint_url


def get_data_from_db(endpoint_url, user_key, where = None, fields=None):
    request_url = make_request_url_filter(endpoint_url, where = where, fields=fields)
    # print(request_url)
    response = requests.get(request_url, headers={'user_key': user_key})
    if response.ok:
        return response.json()
    else:
        response.raise_for_status()

def read_prism_cell_from_file(row_metadata_file, items):

    filepath = row_metadata_file

    (headers, data) = parse_data.read_data(filepath)

    data = [x for x in data if x[0][0] != "#"]

    header_map = parse_data.generate_header_map(headers, items, False)

    logger.debug("header_map:  {}".format(header_map))
    return parse_data.parse_data(header_map, data, PrismCell)

def _read_prism_cell_from_db(cell_set_name):
    cell_set_def_url = API_URL + 'cell_set_definition_files/'
    data = get_data_from_db(
        cell_set_def_url,
        where = {'davepool_id':cell_set_name},
        fields= CELL_SET_DEFINITION_HEADERS,
        user_key=API_KEY)

    return parse_data.parse_json(data, PrismCell)

def build_prism_cell_list(config_parser, cell_set_definition_file):
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
    prism_cell_list = read_prism_cell_from_file(cell_set_definition_file, prism_cell_list_items)

    return prism_cell_list

def build_prism_cell_list_from_db(cell_set_name):
    '''
    read PRISM cell line metadata from file specified in config file, then associate with
    assay_plate based on pool ID, pulling out metadata based on config specifications.  Check for cell pools that are not associated with any assay plate
    :param config_parser: parser pre-loaded with config file
    :param cell_set_definition_file:
    :param analyte_mapping_file:
    :return:
    '''

    #read headers to pull from config and convert to tuple format expected by data parser
    prism_cell_list = _read_prism_cell_from_db(cell_set_name)

    return prism_cell_list


def build_perturbagens_from_file(filepath, pert_time):

    perturbagens = _read_perturbagen_from_file(filepath, do_keep_all=True)
    _add_pert_time_info(perturbagens, pert_time)

    return perturbagens

def build_perturbagens_from_db(map_src_name, pert_time):

    perturbagens = _read_perturbagen_from_db(map_src_name, do_keep_all=True)
    _add_pert_time_info(perturbagens, pert_time)

    return perturbagens


def _read_perturbagen_from_file(filepath, do_keep_all):

    (headers, data) = parse_data.read_data(filepath)

    #todo: think about other checks / better notification of wrong map type
    if "well_position" in headers:
        Exception("Merino no longer supports CM map type, please convert map to CMap map type")

    header_map = parse_data.generate_header_map(headers, None, do_keep_all)
    logger.debug("header_map:  {}".format(header_map))

    return parse_data.parse_data(header_map, data, Perturbagen)

def _read_perturbagen_from_db(map_src_name, do_keep_all):
    tok = map_src_name.split('.')
    pert_plate, replicate = tok[0],tok[1]

    map_src_url = API_URL + 'v_plate_map_src/'
    data = get_data_from_db(
        map_src_url,
        user_key=API_KEY,
        where={'pert_plate': pert_plate, 'replicate': replicate}
    )

    return parse_data.parse_json(data, Perturbagen)



def _add_pert_time_info(perturbagens, pert_time):

    pert_time_unit = "h"

    for p in perturbagens:
        p.pert_time = pert_time
        p.pert_time_unit = pert_time_unit
        p.pert_itime = p.pert_time + " " + p.pert_time_unit


def convert_objects_to_metadata_df(index_builder, object_list, meta_renaming_map):
    """

    :param index_builder: Function that given a provided entry in object_list provides a unique index for that entry
    :param object_list: List of objects that should be converted into rows in the data frame. The properties of these
    objects will be the columns of the data frame.
    :param meta_renaming_map: A mapping between the name of a property and the column header to be used in the output.
    :return: A dataframe where each row corresponds to one of the objects in the object list.
    """
    logger.debug("len(object_list):  {}".format(len(object_list)))

    col_metadata_map = {}
    for p in object_list:
        for k in p.__dict__.keys():
            if k not in col_metadata_map:
                col_metadata_map[k] = []
 
    logger.debug("col_metadata_map.keys():  {}".format(col_metadata_map.keys()))
    index = []
    for p in object_list:
        index.append(index_builder(p))

        for (field, list) in col_metadata_map.items():
            value = p.__dict__[field] if field in p.__dict__ else None
            list.append(value)

    if meta_renaming_map is not None:
        for (original_name, new_name) in meta_renaming_map.items():
            if new_name not in col_metadata_map:
                col_metadata_map[new_name] = col_metadata_map[original_name]
                del col_metadata_map[original_name]
            else:
                raise Exception("prism_metadata convert_perturbagen_list_to_col_metadata_df conflict in column names - renaming "
                                "column will erase existing data.  col_meta_renaming_map:  {}  col_metadata_map.keys():  {}".format(
                    meta_renaming_map, col_metadata_map.keys()
                ))

    return pandas.DataFrame(col_metadata_map, index=index)



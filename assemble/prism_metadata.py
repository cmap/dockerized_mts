import merino.setup_logger as setup_logger
import logging
import pandas
import parse_data

logger = logging.getLogger(setup_logger.LOGGER_NAME)

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

def read_prism_cell_from_file(row_metadata_file, items):

    filepath = row_metadata_file

    (headers, data) = parse_data.read_data(filepath)

    data = [x for x in data if x[0][0] != "#"]

    header_map = parse_data.generate_header_map(headers, items, False)

    logger.debug("header_map:  {}".format(header_map))
    return parse_data.parse_data(header_map, data, PrismCell)


def build_perturbagens_from_file(filepath, pert_time):

    perturbagens = _read_perturbagen_from_file(filepath, do_keep_all=True)
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



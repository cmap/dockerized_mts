
import urllib2
import merino.setup_logger as setup_logger
import logging
import merino.utils.path_utils as path_utils
logger = logging.getLogger(setup_logger.LOGGER_NAME)

def parse_data(header_map, data, BuildClass):
    r = []
    for row in data:
        bc = BuildClass()
        r.append(bc)
        for (h,i) in header_map.items():
            if len(row) > i:
                raw_value = row[i]
                val = parse_raw_value(raw_value)

                bc.__dict__[h] = val

    return r


def parse_raw_value(raw_value):
    val = raw_value
    if val == "":
        val = None
    else:
        try:
            val = int(val)
        except ValueError:
            try:
                val = float(val)
            except ValueError:
                pass

    return val

#todo: re-write to pull out subset of headers, header mapping no longer necessary
def generate_header_map(headers, internal_header_file_header_pairs, do_keep_all):
    """
    creates a mapping between all headers and a subset of headers (indicated by internal_header_file_header_pairs)
    allowing for changes to be made to the original header naming scheme (a currently deprecated utility)

    :param headers: (list of strings) list of all headers in file
    :param internal_header_file_header_pairs: (list of tuples) allows headers to be renamed
    :param do_keep_all: (boolean) if false uses internal_header_file_header_pairs to pull out subset of headers
    :return:
    """
    reverse_header_map = {}
    header_map = {}

    if internal_header_file_header_pairs is not None:
        for (c_key, c_header_name) in internal_header_file_header_pairs:
            reverse_header_map[c_header_name] = c_key

    for (i, h) in enumerate(headers):
        if h in reverse_header_map:
            c_key = reverse_header_map[h]
            header_map[c_key] = i
        elif do_keep_all:
            header_map[h] = i

    if len(header_map) == 0:
        raise Exception("prism_metadata _generate_header_map header_map has no entries, possible mismatch between expected and actual columns")

    return header_map


def read_data(tsv_filepath):
    tsv_filepath = path_utils.validate_path_as_uri(tsv_filepath)

    f = urllib2.urlopen(tsv_filepath)
    raw_data = f.read().strip().split("\n")
    f.close()

    split_raw_data = [x.split("\t") for x in raw_data]

    headers = [x.lower() for x in split_raw_data[0]]
    logger.debug("headers:  {}".format(headers))

    data = split_raw_data[1:]
    return (headers, data)




import merino.setup_logger as setup_logger
import logging
import unittest
import ConfigParser
import parse_data as pd

logger = logging.getLogger(setup_logger.LOGGER_NAME)

test_file = "functional_tests/test_prism_metadata/prism_cell_tsv.txt"

_prism_cell_config_file_section = "PrismCell column headers"
_perturbagen_CM_input_config_file_section = "Perturbagen CM input column headers"

class Dummy(object):
    def __repr__(self):
        return " ".join(["{}:{}".format(str(k),str(v)) for (k,v) in self.__dict__.items()])

    def __str__(self):
        return self.__repr__()


class TestParseData(unittest.TestCase):
    def test_read_data(self):
        (h, d) = pd.read_data(test_file)

        assert h is not None
        logger.debug("h:  {}".format(h))
        assert "pool_id" in h

        assert d is not None
        logger.debug("d:  {}".format(d))
        assert len(d) > 0

    def test_generate_header_map(self):
        #happy path ignore extra field
        headers = ["pool_id", "analyte", "strippedname", "extra_header"]

        cp = ConfigParser.RawConfigParser()
        cp.read("prism_pipeline.cfg")
        internal_header_file_header_pairs = cp.items(_prism_cell_config_file_section)

        r = pd.generate_header_map(headers, internal_header_file_header_pairs, False)
        logger.debug("r:  {}".format(r))
        assert len(r) == 3, len(r)
        assert "extra_header" not in r, r
        assert "pool_id" in r, r
        assert r["pool_id"] == 0, r["pool_id"]

        #happy path include extra field
        r = pd.generate_header_map(headers, internal_header_file_header_pairs, True)
        logger.debug("r:  {}".format(r))
        assert len(r) == 4, len(r)
        assert "extra_header" in r
        assert r["extra_header"] == 3, r["extra_header"]

    def test__parse_data(self):
        headers = ["pool_id", "analyte", "strippedname"]
        cp = ConfigParser.RawConfigParser()
        cp.read("prism_pipeline.cfg")

        header_map = pd.generate_header_map(headers, cp.items(_prism_cell_config_file_section), False)

        data = [["1", "analyte 2", "my cell's name"], ["3", "analyte 5", "autre cell nom"]]

        r = pd.parse_data(header_map, data, Dummy)
        logger.debug("r:  {}".format(r))
        assert len(r) == len(data), len(r)

        header_map["extra header that doesn't have data in any row"] = 10
        r = pd.parse_data(header_map, data, Dummy)
        logger.debug("r:  {}".format(r))
        assert len(r) == len(data), len(r)

        data.append(["7", "", "blah"])
        r = pd.parse_data(header_map, data, Dummy)
        assert r[2].analyte_id is None

        headers = ["well_position", "compound_well_mmoles_per_liter", "dilution_factor"]
        cp = ConfigParser.RawConfigParser()
        cp.read("prism_pipeline.cfg")
        header_map = pd.generate_header_map(headers, cp.items(_perturbagen_CM_input_config_file_section), False)

        data = [["A01", "1.010101", "2"], ["B07", "3.030303", "5"]]
        r = pd.parse_data(header_map, data, Dummy)
        logger.debug("r:  {}".format(r))
        assert len(r) == len(data), len(r)

        assert hasattr(r[0], "compound_well_mmoles_per_liter"), r[0].__dict__
        assert isinstance(r[0].compound_well_mmoles_per_liter, float)

        assert r[0].compound_well_mmoles_per_liter == 1.010101, r[0].compound_well_mmoles_per_liter
        assert isinstance(r[0].dilution_factor, int)
        assert r[0].dilution_factor == 2, r[0].dilution_factor
        assert isinstance(r[1].compound_well_mmoles_per_liter, float)
        assert isinstance(r[1].dilution_factor, int)

    def test__parse_raw_value(self):
        r = pd.parse_raw_value("")
        assert r is None

        r = pd.parse_raw_value("6")
        assert r == 6, r

        r = pd.parse_raw_value("6.1")
        assert r == 6.1, r

        r = pd.parse_raw_value("hello world")
        assert r == "hello world", r


if __name__ == "__main__":
    setup_logger.setup(verbose=True)

    unittest.main()

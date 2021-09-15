import logging
import merino.setup_logger as setup_logger
import unittest
import davepool_data

logger = logging.getLogger(setup_logger.LOGGER_NAME)


class TestDavepoolData(unittest.TestCase):
    def test___init__(self):
        r = davepool_data.DavepoolData()
        assert hasattr(r, "median_headers")

    def test_read_data(self):
        csv_filepath = "../functional_tests/test_data/PASG/lxb/PASG003_PR500.2_120H_X251_BX/PASG003_PR500.2_120H_X251_BX.csv"
        r = davepool_data.read_data(csv_filepath)
        assert r is not None
        assert r.csv_filepath == csv_filepath, r.csv_filepath
        assert r.csv_datetime is not None
        assert r.median_headers is not None
        assert r.median_data is not None
        assert r.count_headers is not None
        assert r.count_data is not None

        logger.debug("r.csv_datetime:  {}".format(r.csv_datetime))

    def test_read_data_from_jcsv(self):
        csv_filepath = "../functional_tests/test_data/PGUM/lxb/PGUM001_KJ100_120H_X1_BX/PGUM001_KJ100_120H_X1_BX.jcsv"
        r = davepool_data.read_data(csv_filepath)

        assert len(r.count_data) == 384, len(r.count_data)

    def test_get_datatype_range(self):
        data = [["a"], range(3), ["DataType:","my type"], range(4), range(5)]

        r = davepool_data.get_datatype_range(data, ["my type"])

        assert r is not None
        logger.debug("r:  {}".format(r))
        assert "my type" in r
        r = r["my type"]
        assert r[0] == 2, r[0]
        assert r[1] == 6, r[1]

        r = davepool_data.get_datatype_range(data, ["unfounded"])
        assert r is not None
        logger.debug("r:  {}".format(r))
        assert "unfounded" in r
        r = r["unfounded"]
        assert r[0] is None, r[0]
        assert r[1] is None, r[1]

        data.append(["DataType:", "another type"])
        data.append(range(6))
        r = davepool_data.get_datatype_range(data, ["my type"])

        assert r is not None
        logger.debug("r:  {}".format(r))
        assert "my type" in r
        r = r["my type"]
        assert r[0] == 2, r[0]
        assert r[1] == 5, r[1]

    def test_get_datetime_from_header_rows(self):
        header_rows = [[],["a","b","c"], range(5), [davepool_data.date_header, "first", "second"], [], range(7)]
        r = davepool_data.get_datetime_from_header_rows(header_rows, "fake csv_filepath")
        logger.debug("r:  {}".format(r))
        assert r == "first second", r

        header_rows.append([davepool_data.date_header, "problem", "entry"])
        with self.assertRaises(Exception) as context:
            davepool_data.get_datetime_from_header_rows(header_rows, "fake csv_filepath")
        logger.debug("context.exception:  {}".format(context.exception))
        assert "expected to find only one datetime_row, found datetime_row:" in str(context.exception), str(context.exception)

    def test_validate_data(self):
        dd = davepool_data.DavepoolData()

        #happy path
        dd.median_data = [[0], [1]]
        dd.count_data = [[2], [3]]
        dd.validate_data()

        #invalid data path
        dd.median_data[1].pop(0)
        with self.assertRaises(Exception) as context:
            dd.validate_data()
        assert context.exception is not None
        logger.debug("context.exception:  {}".format(context.exception))
        assert "data row is empty" in str(context.exception)


if __name__ == "__main__":
    setup_logger.setup(verbose=True)

    unittest.main()

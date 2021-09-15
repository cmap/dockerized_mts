import assemble
import unittest
import merino.setup_logger as setup_logger
import logging
import os
import glob
import mock


logger = logging.getLogger(setup_logger.LOGGER_NAME)


class TestAssemble(unittest.TestCase):

    def test_read_davepool_data_objects(self):
        l = [(1, "../functional_tests/test_data/PASG/lxb/PASG003_PR500.2_120H_X251_BX/PASG003_PR500.2_120H_X251_BX.csv"), (2, "../functional_tests/test_data/PASG/lxb/PASG003_PR500.2_120H_X252_BX/PASG003_PR500.2_120H_X252_BX.csv")]
        r = assemble.read_davepool_data_objects(l)
        assert len(r) > 0
        logger.debug("r:  {}".format(r))

        assert r[0].davepool_id == 1, r[0].davepool_id
        assert r[1].davepool_id == 2, r[1].davepool_id


    def test_build_davepool_id_csv_list(self):
        r = assemble.build_davepool_id_csv_list(["a", "1", "b", "2", "c", "3"])
        logger.debug("r:  {}".format(r))
        assert len(r) == 3, len(r)

        assert r[0][0] == "a", r[0][0]
        assert r[0][1] == "1", r[0][1]
        assert r[2][0] == "c", r[2][0]
        assert r[2][1] == "3", r[2][1]

    def test_full_functional_DP78(self):
        expected_files = ["assemble/PDOG003_DP78_120H_X1_B1/PDOG003_DP78_120H_X1_B1_COUNT.gct",
                          "assemble/PDOG003_DP78_120H_X1_B1/PDOG003_DP78_120H_X1_B1_MEDIAN.gct",
                          "assemble/PDOG003_DP78_120H_X1_B1/config.yaml",
                          "assemble/PDOG003_DP78_120H_X1_B1/success.txt"]
        for ef in expected_files:
            if os.path.exists(ef):
                os.remove(ef)


        config_filepath = "../prism_pipeline.cfg"

        plate_map_path = '../functional_tests/test_data/PDOG/map_src/PDOG003.src'
        dp7_csv_path = "../functional_tests/test_data/PDOG/lxb/PDOG003_DP7_120H_X1_B1/PDOG003_DP7_120H_X1_B1.csv"
        dp8_csv_path = "../functional_tests/test_data/PDOG/lxb/PDOG003_DP8_120H_X1_B1/PDOG003_DP8_120H_X1_B1.csv"
        assay_type = "DP78"

        args = assemble.build_parser().parse_args(["-config_filepath", config_filepath,
            "-pmp", plate_map_path, "-dp_csv", "DP7", dp7_csv_path, "DP8", dp8_csv_path,
                                                   "-at", assay_type])

        logger.debug("args:  {}".format(args))

        assemble.main(args)

        for ef in expected_files:
            assert os.path.exists(ef), ef
            os.remove(ef)
        os.rmdir("assemble/PDOG003_DP78_120H_X1_B1")
        os.rmdir("assemble")

        #for map_file in glob.glob('PDOG*.src'):
        #    x = os.path.getsize(map_file)
        #    assert x > 0
        #    os.remove(map_file)

    def test_full_functional_PR500(self):
        expected_files = ["assemble/PASG003_PR500.2_120H_X251_BX/PASG003_PR500.2_120H_X251_BX_COUNT.gct",
                          "assemble/PASG003_PR500.2_120H_X251_BX/PASG003_PR500.2_120H_X251_BX_MEDIAN.gct",
                          "assemble/PASG003_PR500.2_120H_X251_BX/config.yaml",
                          "assemble/PASG003_PR500.2_120H_X251_BX/success.txt"]
        for ef in expected_files:
            if os.path.exists(ef):
                os.remove(ef)

        config_filepath = "../prism_pipeline.cfg"

        plate_map_path = '../functional_tests/test_data/PASG/map_src/PASG003.src'
        csv_path = "../functional_tests/test_data/PASG/lxb/PASG003_PR500.2_120H_X251_BX/PASG003_PR500.2_120H_X251_BX.csv"
        assay_type = "PR500"

        args = assemble.build_parser().parse_args(["-config_filepath", config_filepath, "-pmp", plate_map_path,
                                                   "-csv", csv_path,  "-at", assay_type])

        logger.debug("args:  {}".format(args))

        assemble.main(args)

        for ef in expected_files:
            assert os.path.exists(ef), ef
            os.remove(ef)
        os.rmdir("assemble/PASG003_PR500.2_120H_X251_BX")
        os.rmdir("assemble")

        for map_file in glob.glob('PASG*.src'):
            x = os.path.getsize(map_file)
            assert x > 0
            os.remove(map_file)


    def test_full_functional_PR300(self):
        # the plate_map in test_data is CM map, and thus fails header checks within validate_prism_gct
        # mocking the column metadata fields within output validation function given
        # the real test here is analyte and cell set mapping

        expected_files = ["assemble/PSPA001_PR300_120H_X1_BX/PSPA001_PR300_120H_X1_BX_COUNT.gct",
                          "assemble/PSPA001_PR300_120H_X1_BX/PSPA001_PR300_120H_X1_BX_MEDIAN.gct",
                          "assemble/PSPA001_PR300_120H_X1_BX/config.yaml",
                          "assemble/PSPA001_PR300_120H_X1_BX/success.txt"]

        for ef in expected_files:
            if os.path.exists(ef):
                os.remove(ef)

        config_filepath = "../prism_pipeline.cfg"

        plate_map_path = '../functional_tests/test_data/PSPA/map_src/PSPA001.src'
        csv_path = "../functional_tests/test_data/PSPA/lxb/PSPA001_PR300_120H_X1_BX/PSPA001_PR300_120H_X1_BX.csv"
        assay_type = "PR300"

        args = assemble.build_parser().parse_args(["-config_filepath", config_filepath, "-pmp", plate_map_path,
                                                   "-csv", csv_path, "-at", assay_type])

        logger.debug("args:  {}".format(args))

        assemble.main(args)

        for ef in expected_files:
            assert os.path.exists(ef), ef
            os.remove(ef)
        os.rmdir("assemble/PSPA001_PR300_120H_X1_BX")
        os.rmdir("assemble")

        for map_file in glob.glob('PSPA*.src'):
            x = os.path.getsize(map_file)
            assert x > 0
            os.remove(map_file)

    def test_full_functional_COPRO(self):
        expected_files = ["assemble/PGUM001_KJ100_120H_X1_BX/PGUM001_KJ100_120H_X1_BX_COUNT.gct",
                          "assemble/PGUM001_KJ100_120H_X1_BX/PGUM001_KJ100_120H_X1_BX_MEDIAN.gct",
                          "assemble/PGUM001_KJ100_120H_X1_BX/config.yaml",
                          "assemble/PGUM001_KJ100_120H_X1_BX/success.txt"]

        for ef in expected_files:
            if os.path.exists(ef):
                os.remove(ef)

        config_filepath = "../prism_pipeline.cfg"

        plate_map_path = '../functional_tests/test_data/PGUM/map_src/PGUM001.src'
        csv_path = "../functional_tests/test_data/PGUM/lxb/PGUM001_KJ100_120H_X1_BX/PGUM001_KJ100_120H_X1_BX.jcsv"
        assay_type = "KJ100"

        args = assemble.build_parser().parse_args(["-config_filepath", config_filepath, "-pmp", plate_map_path,
                                                   "-csv", csv_path,  "-at", assay_type])

        logger.debug("args:  {}".format(args))

        assemble.main(args)

        for ef in expected_files:
            assert os.path.exists(ef), ef
            os.remove(ef)
        os.rmdir("assemble/PGUM001_KJ100_120H_X1_BX")
        os.rmdir("assemble")

        for map_file in glob.glob('PGUM*.src'):
            x = os.path.getsize(map_file)
            assert x > 0
            os.remove(map_file)

if __name__ == "__main__":
    setup_logger.setup(verbose=True)

    unittest.main()

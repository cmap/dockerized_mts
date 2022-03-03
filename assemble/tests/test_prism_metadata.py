import merino.setup_logger as setup_logger
import logging
import unittest
import prism_metadata as pm
import ConfigParser


logger = logging.getLogger(setup_logger.LOGGER_NAME)

test_file = "functional_tests/test_prism_metadata/prism_cell_tsv.txt"


class TestPrismMetadata(unittest.TestCase):
    def test___init__(self):
        r = pm.PrismCell()
        assert hasattr(r, "pool_id")
        assert hasattr(r, "analyte_id")

    def test_read_prism_cell_from_file(self):
        cp = ConfigParser.RawConfigParser()
        config_filepath = 'prism_pipeline.cfg'
        cp.read(config_filepath)

        prism_cell_list_items = cp.items("PrismCell column headers")
        davepool_mapping_items = cp.items("DavepoolAnalyteMapping column headers")

        cell_set_definition = "requirements_artifacts/Tranche1PrimaryMetaData_02252016.txt"
        r = pm.read_prism_cell_from_file(cell_set_definition, prism_cell_list_items)
        self.assertGreater(len(r), 20)
        logger.debug("r[0:10]:  {}".format(r[0:10]))

        r = pm.read_prism_cell_from_file("functional_tests/test_prism_metadata/test_read_prism_cell_from_file/test_cell_definition.txt",
                                         prism_cell_list_items)
        self.assertEqual(8, len(r))
        logger.debug("r[0:8]:  {}".format(r[0:10]))

        #check that commented out line is ignored when reading in cell metadata
        c = [x for x in r if x.id == 4]
        logger.debug("c:  {}".format(c))
        self.assertEqual(0, len(c), "expected that cell line with id == 5 was not read in because it is commented out in " +
                         "test_cell_definition.txt, but it was found")

    def test__read_perturbagen_from_file_CM(self):
        r = pm._read_perturbagen_from_file("functional_tests/test_prism_metadata/perturbagen.txt",
                                           pm._perturbagen_CM_input_config_file_section, False)

        assert len(r) > 0
        for x in r:
            logger.debug("x:  {}".format(x))

    def test__read_perturbagen_from_file_CMap(self):
        #1 perturbagen per well
        r = pm._read_perturbagen_from_file("functional_tests/test_prism_metadata/LJP005.src",
                                           pm._perturbagen_CMap_input_config_file_section, True)
        assert len(r) > 0, len(r)
        logger.debug("r[0]:  {}".format(r[0]))
        logger.debug("r[6]:  {}".format(r[6]))

        assert r[0].well_id is not None
        assert hasattr(r[0], "pert_id")
        assert hasattr(r[0], "pert_type")

        #multiple perturbagens per well
        r = pm._read_perturbagen_from_file("functional_tests/test_prism_metadata/PMEL.A001.src",
                                           pm._perturbagen_CMap_input_config_file_section, True)

        assert len(r) > 0, len(r)
        logger.debug("r[0]:  {}".format(r[0]))
        logger.debug("r[6]:  {}".format(r[6]))

        assert r[0].well_id is not None
        assert hasattr(r[0], "pert_id")
        assert hasattr(r[0], "pert_type")

    def test_read_assay_plate_from_file(self):
        r = pm.read_assay_plate_from_file("functional_tests/test_prism_metadata/assay_plate.txt")
        assert len(r) > 0
        for x in r:
            logger.debug("x:  {}".format(x))
            assert x.assay_plate_barcode is not None
            assert x.det_plate is not None
            assert x.pool_id is not None

    def test__build_additional_perturbagen_info(self):
        p = pm.Perturbagen()
        #worst case scenario, these are both ints
        p.compound_well_mmoles_per_liter = int(5)
        p.dilution_factor = int(2001)
        p.pert_mfc_id = "BRD-K12345678-910-11-1"
        p.pert_type = "Test"
        p.pert_mfc_desc = "my fake compound name"

        pm._build_additional_perturbagen_info([p])
        logger.debug("p:  {}".format(p))
        assert p.pert_dose == (1000.0 * float(5) / 2001.0), p.pert_dose
        assert p.pert_dose_unit == "uM", p.pert_dose_unit
        assert p.pert_idose is not None

        assert p.pert_id == "BRD-K12345678", p.pert_id
        assert p.pert_type == "trt_cp", p.pert_type
        assert p.pert_iname == "my fake compound name", p.pert_iname
        assert p.pert_time == "120", p.pert_time
        assert p.pert_time_unit == "h", p.pert_time_unit
        assert p.pert_itime == "120 h", p.pert_itime

        p.pert_mfc_desc = None
        pm._build_additional_perturbagen_info([p])
        assert p.pert_iname == p.pert_id, p.pert_iname

        p.pert_type = "unrecognized"
        pm._build_additional_perturbagen_info([p])
        assert p.pert_type == "ctl_vehicle", p.pert_type

        p.pert_type = None
        pm._build_additional_perturbagen_info([p])
        assert p.pert_type == "ctl_vehicle", p.pert_type

        p.pert_mfc_id = None
        pm._build_additional_perturbagen_info([p])
        assert p.pert_id == "DMSO", p.pert_id

        p.compound_well_mmoles_per_liter = "not a valid concentration"
        with self.assertRaises(Exception) as context:
            pm._build_additional_perturbagen_info([p])
        assert context.exception is not None
        logger.debug("context.exception:  {}".format(context.exception))
        assert "the concentration or dilution factors should be numbers" in str(context.exception), \
            str(context.exception)

        p.compound_well_mmoles_per_liter = 5.0
        del p.pert_type
        with self.assertRaises(Exception) as context:
            pm._build_additional_perturbagen_info([p])
        assert context.exception is not None
        logger.debug("context.exception:  {}".format(context.exception))
        assert "pert_type attribute is missing from perturbagen" in str(context.exception), str(context.exception)

    def test__build_additional_perturbagen_info_vehicle(self):
        p = pm.Perturbagen()
        p.pert_type = "Empty"
        p.pert_vehicle = "DMSO"
        p.compound_well_mmoles_per_liter = None
        p.pert_mfc_id = None

        pm._build_additional_perturbagen_info([p])
        logger.debug("p:  {}".format(p))

        assert p.pert_dose is None, p.pert_dose
        assert p.pert_dose_unit is None, p.pert_dose_unit
        assert p.pert_idose is None, p.pert_idose

    def test_validate_perturbagens(self):
        perts = []
        num_wells = 3

        for assay_plate_barcode in ["a" + str(i) for i in range(2)]:
            new_perts = [pm.Perturbagen(well_id=i) for i in range(num_wells)]
            for (i, np) in enumerate(new_perts):
                np.assay_plate_barcode = assay_plate_barcode
                np.pert_id = "BRD-K" + str(int(11.0*i))
                np.pert_idose = str(13.0*i) + " uM"
            perts.extend(new_perts)
        logger.debug("perts:  {}".format(perts))

        r = pm.validate_perturbagens(perts)
        logger.debug("r:  {}".format(r))

        assert len(r) == num_wells, (len(r), num_wells)
        for i in range(num_wells):
            assert i in r
            assert r[i].well_id == i, r[i]

        perts[num_wells].pert_id = perts[0].pert_id + " extra junk"
        with self.assertRaises(Exception) as context:
            pm.validate_perturbagens(perts)
        assert context.exception is not None
        logger.debug("context.exception:  {}".format(context.exception))
        assert "the perturbagens provided contain different compounds in the same wells of different assasy plates" in \
               str(context.exception), str(context.exception)

    def test_convert_objects_to_metadata_df(self):
        col_base_id = "my col base id"
        pert_list = [pm.Perturbagen("A01"), pm.Perturbagen("B02"), pm.Perturbagen(3)]
        for (i, p) in enumerate(pert_list):
            p.pert_type = "trt_cp"
            p.random_inclusion = i
            p.other = None
            p.something = i*1.1

        def index_builder(pert):
            return col_base_id + ":" + str(pert.well_id)

        r = pm.convert_objects_to_metadata_df(index_builder, pert_list)
        assert r is not None
        logger.debug("r:  {}".format(r))

        assert pm.cmap_pert_well in r.columns
        assert "pert_type" in r.columns
        assert "random_inclusion" in r.columns
        assert "other" in r.columns
        assert "something" in r.columns

        expected_col_id = index_builder(pert_list[0])
        assert expected_col_id in r.index, (expected_col_id, r.index)
        expected_col_id = index_builder(pert_list[2])
        assert expected_col_id in r.index, (expected_col_id, r.index)

        assert "trt_cp" == r["pert_type"][expected_col_id], r["pert_type"][expected_col_id]
        assert 2 == r["random_inclusion"][expected_col_id], r["random_inclusion"][expected_col_id]
        assert r["other"][expected_col_id] is None, r["other"][expected_col_id]
        assert 2.2 == r["something"][expected_col_id], r["something"][expected_col_id]
        assert 3 == r["pert_well"][expected_col_id], r["pert_well"][expected_col_id]

    def test_convert_objects_to_metadata_df_for_prism_cell(self):
        cell_list = [pm.PrismCell(1, 2, 3, 5), pm.PrismCell(7, 11, 13, 17)]

        def index_builder(c):
            return c.id

        r = pm.convert_objects_to_metadata_df(index_builder, cell_list)

        assert r is not None
        logger.debug("r:  {}".format(r))

        assert "pool_id" in r.columns
        assert "davepool_id" in r.columns
        assert "analyte_id" in r.columns


if __name__ == "__main__":
    setup_logger.setup(verbose=True)

    unittest.main()

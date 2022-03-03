import assemble_core
import unittest
import merino.setup_logger as setup_logger
import logging
import prism_metadata
import davepool_data
import numpy
import os
import glob


logger = logging.getLogger(setup_logger.LOGGER_NAME)


class TestAssembleWithObjects(unittest.TestCase):
    def test_build_davepool_to_cells_map(self):
        l = [prism_metadata.PrismCell(pool_id=str(x + 20), analyte_id=str(x + 10), davepool_id=str(x / 2)) for x in range(6)]
        logger.debug("l:  {}".format(l))

        r = assemble_core.build_davepool_id_to_cells_map(l)
        assert len(r) == 3, len(r)
        logger.debug("r:  {}".format(r))

        for x in range(3):
            y = str(x)
            assert y in r, y
            assert len(r[y]) == 2, r[y]

    def test_build_data_by_cell(self):
        cells = [prism_metadata.PrismCell(pool_id=str(x + 20), analyte_id=str(x + 10), davepool_id=str(x / 2)) for x in range(2)]
        logger.debug("cells:  {}".format(cells))

        davepool_data_obj = davepool_data.DavepoolData()
        davepool_data_obj.median_headers = ["Location", "10", "11"]
        davepool_data_obj.median_headers.extend([str(x) for x in range(30,40)])

        davepool_data_obj.median_data = {"A01": [1,2], "J13": [3,5]}
        davepool_data_obj.median_data['A01'].extend([x for x in range(40,50)])
        davepool_data_obj.median_data['J13'].extend([x for x in range(50,60)])

        davepool_data_obj.count_headers = davepool_data_obj.median_headers
        davepool_data_obj.count_data = {"B03": [7,11], "L17": [13,17]}
        davepool_data_obj.count_data["B03"].extend([x for x in range(60,70)])
        davepool_data_obj.count_data["L17"].extend([x for x in range(70,80)])
        logger.debug("davepool_data_obj:  {}".format(davepool_data_obj))

        rep = assemble_core.build_data_by_cell(cells, davepool_data_obj)

        r_med = rep[0]
        assert r_med is not None
        logger.debug("r_med:  {}".format(r_med))
        assert r_med.well_list is not None
        assert len(r_med.well_list) == 2, len(r_med.well_list)
        assert "A01" in r_med.well_list, r_med.well_list
        assert "J13" in r_med.well_list, r_med.well_list
        assert len(r_med.cell_data_map) == len(cells), (len(r_med.cell_data_map), len(cells))


        r_count = rep[1]
        assert len(r_count.well_list) == 2, len(r_count.well_list)
        logger.debug("r_count.well_list:  {}".format(r_count.well_list))
        assert "B03" in r_count.well_list, r_count.well_list
        assert "L17" in r_count.well_list, r_count.well_list

        assert len(r_count.cell_data_map) == len(cells), (len(r_count.cell_data_map), len(cells))
        logger.debug("r_count.cell_data_map:  {}".format(r_count.cell_data_map))

    def test_process_data(self):
        cells = [prism_metadata.PrismCell(pool_id=str(x + 20), analyte_id=str(x + 10), davepool_id=str(x / 2)) for x in range(4)]
        logger.debug("cells:  {}".format(cells))
        cells_map = assemble_core.build_davepool_id_to_cells_map(cells)
        logger.debug("cells_map:  {}".format(cells_map))

        davepool_list = []
        davepool_data_obj = davepool_data.DavepoolData()
        davepool_list.append(davepool_data_obj)

        davepool_data_obj.davepool_id = "0"
        davepool_data_obj.median_headers = [str(x) for x in range(10,22)]
        davepool_data_obj.median_headers.insert(0, "Location")
        davepool_data_obj.median_data = {"A01": [1,2], "J13": [3,5]}
        davepool_data_obj.median_data["A01"].extend([x for x in range(40,50)])
        davepool_data_obj.median_data["J13"].extend([x for x in range(50,60)])

        davepool_data_obj.count_headers = davepool_data_obj.median_headers
        davepool_data_obj.count_data = {"A01": [7,11], "J13": [13,17]}
        davepool_data_obj.count_data["A01"].extend([x for x in range(60,70)])
        davepool_data_obj.count_data["J13"].extend([x for x in range(70,80)])
        logger.debug("davepool_data_obj:  {}".format(davepool_data_obj))

        davepool_data_obj = davepool_data.DavepoolData()
        davepool_list.append(davepool_data_obj)

        davepool_data_obj.davepool_id = "1"
        davepool_data_obj.median_headers = [str(x) for x in range(10,22)]
        davepool_data_obj.median_headers.insert(0, "Location")
        davepool_data_obj.median_data = {"A01": [-1,-2,19,23], "J13": [-3,-5,29,31]}
        davepool_data_obj.median_data["A01"].extend([x for x in range(80,88)])
        davepool_data_obj.median_data["J13"].extend([x for x in range(90,98)])

        davepool_data_obj.count_headers = davepool_data_obj.median_headers
        davepool_data_obj.count_data = {"A01": [-7,-11,37,41], "J13": [-13,-17,43,47]}
        davepool_data_obj.count_data["A01"].extend([x for x in range(100,108)])
        davepool_data_obj.count_data["J13"].extend([x for x in range(110,118)])
        logger.debug("davepool_data_obj:  {}".format(davepool_data_obj))

        r = assemble_core.process_data(davepool_list, cells_map)
        assert len(r) == 2, len(r)

        median_data_by_cell = r[0]
        assert median_data_by_cell is not None
        logger.debug("median_data_by_cell:  {}".format(median_data_by_cell))
        assert 2 == median_data_by_cell.cell_data_map[cells[1]][0]
        assert 3 == median_data_by_cell.cell_data_map[cells[0]][1]
        t_wells = median_data_by_cell.well_list
        logger.debug("t_wells:  {}".format(t_wells))
        assert "J13" in t_wells

        assert 23 == median_data_by_cell.cell_data_map[cells[3]][0]
        assert 29 == median_data_by_cell.cell_data_map[cells[2]][1]

    def test_build_gctoo(self):
        filepath = "functional_tests/test_assemble/test_write_output_gct.txt"
        if os.path.exists(filepath):
            os.remove(filepath)

        prn = "my_prism_replicate"

        pert_list = []
        p = prism_metadata.Perturbagen()
        p.pert_well= "J01"
        p.pert_id = "BRD-K12345678"
        p.pert_dose = 11.0
        p.pert_dose_unit = "uM"
        pert_list.append(p)
        p = prism_metadata.Perturbagen()
        p.pert_well = "M03"
        p.pert_id = "BRD-K91011121"
        p.pert_dose = 13.0
        p.pert_dose_unit = "mg/mL"
        pert_list.append(p)
        p = prism_metadata.Perturbagen()
        p.pert_well = "B02"
        p.pert_id = "BRD-K31415171"
        p.pert_dose = 17.0
        p.pert_dose_unit = "nM"
        pert_list.append(p)

        cell_list = []
        c = prism_metadata.PrismCell(pool_id="fake pool", analyte_id="fake analyte",
                                     davepool_id="fake davepool", feature_id='c-3')
        cell_list.append(c)
        c = prism_metadata.PrismCell(pool_id="fake pool 2", analyte_id="fake analyte 2",
                                     davepool_id="fake davepool 2", feature_id='c-5')
        cell_list.append(c)
        c = prism_metadata.PrismCell(pool_id="fake pool 2", analyte_id="fake analyte 3",
                                     davepool_id="fake davepool 2", feature_id='c-7')
        cell_list.append(c)

        data_by_cell = assemble_core.DataByCell({cell_list[1]:[1, 2, 11], cell_list[2]:[13, 17, 19], cell_list[0]:[23, 29, 31]},
                                                ["J01", "M03", "B02"])

        r = assemble_core.build_gctoo(prn, pert_list, data_by_cell)
        self.assertIsNotNone(r)
        logger.debug("r:  {}".format(r))
        logger.debug("r.col_metadata_df:  {}".format(r.col_metadata_df))
        logger.debug("r.row_metadata_df:  {}".format(r.row_metadata_df))
        logger.debug("r.data_df:  {}".format(r.data_df))

    def test_build_gctoo_data_df(self):
        #happy path - all numbers
        cell_id_data_map = {"cell1":[0,1,2,3], "cell2":[5,7,11,13]}
        data_df_column_ids = ["s1", "s2", "s3", "s5"]
        r = assemble_core.build_gctoo_data_df(cell_id_data_map, data_df_column_ids)
        self.assertIsNotNone(r)
        logger.debug("r:  {}".format(r))
        self.assertEquals(True, all(data_df_column_ids == r.columns),
                          "columns of result do not match provided columns - data_df_column_ids:  {}  r.columns:  {}".format(
                              data_df_column_ids, r.columns))
        #check that index entries are present and sorted
        self.assertEquals("cell1", r.index[0])
        self.assertEquals("cell2", r.index[1])

        #2nd happy path - blank entry present in data
        cell_id_data_map["cell1"][1] = ""
        cell_id_data_map["cell2"][2] = ""
        r = assemble_core.build_gctoo_data_df(cell_id_data_map, data_df_column_ids)
        self.assertIsNotNone(r)
        logger.debug("r:  {}".format(r))
        s = r["s2"].loc["cell1"]
        logger.debug("s:  {}".format(s))
        self.assertEquals(assemble_core._NaN, s, "expected blank empty string to be replaced with _NaN, was not")

        s = r["s3"].loc["cell2"]
        logger.debug("s:  {}".format(s))
        self.assertEquals(assemble_core._NaN, s, "expected blank empty string to be replaced with _NaN, was not")




if __name__ == "__main__":
    setup_logger.setup(verbose=True)

    unittest.main()
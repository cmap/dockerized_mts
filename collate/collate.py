import argparse
import glob
import logging
import os
import sys

import cmapPy.pandasGEXpress.GCToo as GCToo
import cmapPy.pandasGEXpress.concat as cg
import cmapPy.pandasGEXpress.parse as pe
import cmapPy.pandasGEXpress.write_gct as wg
import cmapPy.pandasGEXpress.write_gctx as wgx
import merino.build_summary.ssmd_analysis as ssmd
import merino.misc_tools.cut_to_l2 as cut_to_l2
import merino.setup_logger as setup_logger
import pandas as pd
import numpy as np
from math import floor, log10

logger = logging.getLogger(setup_logger.LOGGER_NAME)


def build_parser():

    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    # The following arguments are required. These are files that are necessary for assembly and which change
    # frequently between cohorts, replicates, etc.
    parser.add_argument("--proj_dir", "-pd", help="Required: Path to the pod directory you want to run card on",
                        type=str, required=True)
    parser.add_argument("--cohort_name", "-cn", help="Required: String designating the prefix to each build file eg. PCAL075-126_T2B",
                        type=str, required=True)
    parser.add_argument("--build_dir", "-bd", help="Required: outfolder for build files",
                        type=str, required=True)
    parser.add_argument("--search_pattern", "-sp",
                        help="Search for this string in the directory, only run plates which contain it. "
                             "Default is wildcard",
                        type=str, default='*', required=False)
    parser.add_argument("--verbose", '-v', help="Whether to print a bunch of output", action="store_true", default=False)


    return parser

"""
stringify method to write floats as numerical non-scientific notation
"""
def float_to_str(f):
    float_string = repr(f)
    if 'e' in float_string:  # detect scientific notation
        digits, exp = float_string.split('e')
        digits = digits.replace('.', '').replace('-', '')
        exp = int(exp)
        zero_padding = '0' * (abs(int(exp)) - 1)  # minus 1 for decimal point in the sci notation
        sign = '-' if f < 0 else ''
        if exp > 0:
            float_string = '{}{}{}.0'.format(sign, digits, zero_padding)
        else:
            float_string = '{}0.{}{}'.format(sign, zero_padding, digits)
    return float_string


"""
rounds to significant figures
"""
def _round_sig(x, sig=5):
    return round(x, sig - int(floor(log10(abs(x)))) - 1)


"""
prints string as decimal value not scientific notation
"""
def _format_floats(fl, sig=4, max_precision=50):
    if type(fl) == str:
        fl = float(fl)
    if np.isnan(fl):
        return fl
    else:
        return float_to_str(round(_round_sig(fl, sig=sig), max_precision))


def process_pert_doses(el):
    if type(el) == str:
        #         print(el)
        return '|'.join(map(_format_floats, map(float, el.split('|'))))
    else:
        return _format_floats(el)

def process_pert_idoses(el):
    if type(el) == str:
        #         print(el)
        idoses = el.split('|')
        idoses = [i.split(" ") for i in idoses]
        return "|".join(["{} {}".format(_format_floats(idose[0]), idose[1]) for idose in idoses])
    else:
        return _format_floats(el)

def stringify_inst_doses(inst):
    # cast pert_dose field to str
    inst['pert_dose'] = inst['pert_dose'].apply(
        lambda el: process_pert_doses(el)
    )
    if 'pert_idose' in inst.columns:
        inst['pert_idose'] = inst['pert_idose'].apply(
            lambda el: process_pert_idoses(el)
        )

    inst['pert_dose'] = inst['pert_dose'].astype(str)
    return inst


def build(search_pattern, outfile, file_suffix, cut=True, check_size=False):
    gct_list = glob.glob(search_pattern)
    old_len = len(gct_list)

    if old_len == 0:
        return None, None

    if cut==True:
        gct_list = cut_to_l2.cut_l1(gct_list)

    new_len = len(gct_list)

    logger.info('Number of old lysate plates removed = {}'.format(old_len - new_len))

    if new_len == 0:
        return None, None
    gcts = []
    failure_list = []
    for gct in gct_list:
        temp = pe.parse(gct)
        gcts.append(temp)
        if temp.data_df.shape[1] <= 349 and check_size == True:
            failure_list.append(os.path.basename(gct).replace('_NORM.gct', ''))

    for ct in gcts:
        ct.row_metadata_df = gcts[0].row_metadata_df

    fields_to_remove = [x for x in gcts[0].row_metadata_df.columns if
                        x in ['det_plate', 'det_plate_scan_time', 'assay_plate_barcode']]


    concat_gct = cg.hstack(gcts, False, None, fields_to_remove=fields_to_remove)

    concat_gct_wo_meta = GCToo.GCToo(data_df = concat_gct.data_df, row_metadata_df = pd.DataFrame(index=concat_gct.data_df.index),
                                     col_metadata_df=pd.DataFrame(index=concat_gct.col_metadata_df.index))

    logger.debug("gct shape without metadata: {}".format(concat_gct_wo_meta.data_df.shape))
#    logger.debug(outfile + 'n{}x{}'.format(concat_gct.data_df.shape[1], concat_gct.data_df.shape[0]) + file_suffix)
    wgx.write(concat_gct_wo_meta, outfile + 'n{}x{}'.format(concat_gct.data_df.shape[1], concat_gct.data_df.shape[0]) + file_suffix)

    return concat_gct, failure_list


def mk_gct_list(search_pattern):
    #cut = False
    gct_list = glob.glob(search_pattern)
    old_len = len(gct_list)

    if cut == True:
        gct_list = cut_to_l2.cut_l1(gct_list)

    new_len = len(gct_list)

    print('Number of old lysate plates removed = {}'.format(old_len - new_len))

    if new_len == 0:
        return

    return gct_list


def mk_cell_metadata(args, failed_plates=None):
    mfi_paths = glob.glob(os.path.join(args.proj_dir, args.search_pattern, 'assemble', args.search_pattern, '*MEDIAN.gct'))

    cell_temp = pe.parse(mfi_paths[0])
    cell_temp.row_metadata_df.to_csv(os.path.join(args.build_dir, args.cohort_name + '_cell_info.txt'), sep='\t')

    if failed_plates:
        # Calculate SSMD matrix using paths that were just grabbed and write out
        ssmd_mat = ssmd.ssmd_matrix(cut_to_l2.cut_l1(paths))

        ssmd_gct = GCToo.GCToo(data_df=ssmd_mat, col_metadata_df=pd.DataFrame(index=ssmd_mat.columns),
                               row_metadata_df=pd.DataFrame(index=ssmd_mat.index))
        wg.write(ssmd_gct, os.path.join(args.build_dir, args.cohort_name + '_ssmd_matrix_n{}_{}.gct'.format(ssmd_gct.data_df.shape[1], ssmd_gct.data_df.shape[0])))

        ssmd_failures = ssmd_gct.data_df.median()[ssmd_gct.data_df.median() < 2].index.tolist()
        fails_dict = dict({'dropout_failures': failed_plates, 'ssmd_failures': ssmd_failures})
        fails_df = pd.DataFrame(dict([(k, pd.Series(v)) for k, v in fails_dict.iteritems()]))
        fails_df.to_csv(os.path.join(args.build_dir, 'failed_plates.txt'), sep='\t', index=False)



def mk_inst_info(inst_data, args=None):

    inst_info = inst_data.col_metadata_df
    inst_info['profile_id'] = inst_info.index

    for x in ['data_level', 'provenance']:
        del inst_info[x]

    inst_info.set_index('profile_id', inplace=True)

    # logger.info("Converting pert_dose, pert_idose as strings")
    # inst_info = stringify_inst_doses(inst_info)

    inst_info.to_csv(os.path.join(args.build_dir, args.cohort_name + '_inst_info.txt'), sep='\t')


def main(args):
    search_pattern_dict = {
        '*MEDIAN.gct': ['assemble', '_LEVEL2_MFI_'],
        '*COUNT.gct': ['assemble', '_LEVEL2_COUNT_'],
    }

    data_dict = {}

    for key in search_pattern_dict:
        path = os.path.join(args.proj_dir, args.search_pattern, search_pattern_dict[key][0],
                            args.search_pattern,key)

        out_path = os.path.join(args.build_dir, args.cohort_name + search_pattern_dict[key][1])

        logger.info("working on {}".format(path))

        if 'MODZ' in key:
            data, _ = build(path, out_path, '.gctx', cut=False)
        elif 'NORM' in key:
            data, failure_list = build(path, out_path, '.gctx', cut=True, check_size=True)
        else:
            data, _ = build(path, out_path, '.gctx', cut=True)
        data_dict[key] = data

    mk_inst_info(data_dict['*MEDIAN.gct'], args=args)

    try:
        mk_cell_metadata(args, failure_list)
    except Exception as e:
        mk_cell_metadata(args)

if __name__ == "__main__":
    args = build_parser().parse_args(sys.argv[1:])
    setup_logger.setup(verbose=args.verbose)

    logger.debug("args:  {}".format(args))

    if not os.path.exists(args.build_dir):
        logger.info("Making build directory: {}".format(args.build_dir))
        os.mkdir(args.build_dir)

    main(args)

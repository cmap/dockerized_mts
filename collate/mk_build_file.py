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

logger = logging.getLogger(setup_logger.LOGGER_NAME)


def build_parser():

    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    # The following arguments are required. These are files that are necessary for assembly and which change
    # frequently between cohorts, replicates, etc.
    parser.add_argument("-proj_dir", "-pd", help="path to the pod directory you want to run card on",
                        type=str, required=True)
    parser.add_argument("-cohort_name", "-cn", help="string designating the prefix to each build file eg. PCAL075-126_T2B",
                        type=str, required=True)
    parser.add_argument("-build_folder", "-bf", help="outfolder for build files",
                        type=str, required=True)
    parser.add_argument("-search_pattern", "-sp",
                        help="Search for this string in the directory, only run plates which contain it. "
                             "Default is wildcard",
                        type=str, default='*', required=False)
    parser.add_argument("-aggregate_out", "-agg", help="whether weave used aggregate_out flag", action="store_true", default=False)
    parser.add_argument("-verbose", '-v', help="Whether to print a bunch of output", action="store_true", default=False)
    parser.add_argument("-bad_wells", "-wells", help="List of wells to be excluded from processing", type=list,
                        default=[])
    parser.add_argument("-log_tf", "-log", help="True or false, if true log transform the data",
                        action="store_true", default=True)

    return parser

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
    if args.aggregate_out:
        mfi_paths = glob.glob(os.path.join(args.proj_dir, args.search_pattern, 'assemble', '*', '*MEDIAN.gct'))
    else:
        mfi_paths = glob.glob(os.path.join(args.proj_dir, 'assemble', args.search_pattern, '*MEDIAN.gct'))

    cell_temp = pe.parse(mfi_paths[0])
    cell_temp.row_metadata_df.to_csv(os.path.join(args.build_folder, args.cohort_name + '_cell_info.txt'), sep='\t')


    if failed_plates:
        # Calculate SSMD matrix using paths that were just grabbed and write out
        ssmd_mat = ssmd.ssmd_matrix(cut_to_l2.cut_l1(paths))

        ssmd_gct = GCToo.GCToo(data_df=ssmd_mat, col_metadata_df=pd.DataFrame(index=ssmd_mat.columns),
                               row_metadata_df=pd.DataFrame(index=ssmd_mat.index))
        wg.write(ssmd_gct, os.path.join(args.build_folder, args.cohort_name + '_ssmd_matrix_n{}_{}.gct'.format(ssmd_gct.data_df.shape[1], ssmd_gct.data_df.shape[0])))

        ssmd_failures = ssmd_gct.data_df.median()[ssmd_gct.data_df.median() < 2].index.tolist()
        fails_dict = dict({'dropout_failures': failed_plates, 'ssmd_failures': ssmd_failures})
        fails_df = pd.DataFrame(dict([(k, pd.Series(v)) for k, v in fails_dict.iteritems()]))
        fails_df.to_csv(os.path.join(args.build_folder, 'failed_plates.txt'), sep='\t', index=False)

def mk_inst_info(inst_data, norm_data=None, args=None):

    inst_info = inst_data.col_metadata_df
    inst_info['profile_id'] = inst_info.index

    for x in ['data_level', 'provenance']:
        del inst_info[x]

    inst_info.set_index('profile_id', inplace=True)
    inst_info['is_well_failure'] = False

    if norm_data:
        inst_info.loc[[x for x in inst_info.index if x not in norm_data.data_df.columns], 'is_well_failure'] = True

    inst_info.to_csv(os.path.join(args.build_folder, args.cohort_name + '_inst_info.txt'), sep='\t')


def mk_sig_info(search_pattern_dict, data_dict, args):

    for key in search_pattern_dict:

        if 'MODZ' in key:

            jon = pd.DataFrame()

            data_id = key.split('.g')[0].replace('*', '')

            if args.aggregate_out:
                meta_paths = glob.glob(os.path.join(args.proj_dir, args.search_pattern, 'weave', '*{}_cc_q75.txt'.format(data_id)))
            else:
                meta_paths = glob.glob(os.path.join(args.proj_dir, 'weave', args.search_pattern, '*{}_cc_q75.txt'.format(data_id)))


            if len(meta_paths) == 0:
                logger.info("No metadata found for {}".format(data_id))
                continue

            for y in meta_paths:
                temp = pd.read_table(y)

                jon = jon.append(temp)

            jon.set_index('sig_id', inplace=True)

            sig_data = data_dict[key]

            fcpc_sig_info = jon.join(sig_data.col_metadata_df)

            for x in ['data_level', 'prism_replicate', 'det_well']:
                del fcpc_sig_info[x]

            fcpc_sig_info.to_csv(os.path.join(args.build_folder, args.cohort_name + '_sig_metrics_{}.txt'.format(data_id)), sep='\t')


def main(args):
    search_pattern_dict = {'*MEDIAN.gct': ['assemble', '_LEVEL2_MFI_'],
                           '*COUNT.gct': ['assemble', '_LEVEL2_COUNT_'],
                           # '*NORM.gct': ['card', '_LEVEL3_NORM_'],
                           # '*ZSPC.gct': ['card', '_LEVEL4_ZSPC_'],
                           # '*ZSPC.COMBAT.gct': ['card', '_LEVEL4_ZSPC.COMBAT_'],
                           # '*ZSVC.gct': ['card', '_LEVEL4_ZSVC_'],
                           # '*ZSVC.COMBAT.gct': ['card', '_LEVEL4_ZSVC.COMBAT_'],
                           # '*LFCPC.gct': ['card', '_LEVEL4_LFCPC_'],
                           # '*LFCPC.COMBAT.gct': ['card', '_LEVEL4_LFCPC.COMBAT_'],
                           # '*LFCVC.gct': ['card', '_LEVEL4_LFCVC_'],
                           # '*LFCVC.COMBAT.gct': ['card', '_LEVEL4_LFCVC.COMBAT_'],
                           # '*MODZ.ZSPC.gct':['weave', '_LEVEL5_MODZ.ZSPC_'],
                           # '*MODZ.LFCPC.gct':['weave', '_LEVEL5_MODZ.LFCPC_'],
                           # '*MODZ.ZSPC.COMBAT.gct': ['weave', '_LEVEL5_MODZ.ZSPC.COMBAT_'],
                           # '*MODZ.LFCPC.COMBAT.gct': ['weave', '_LEVEL5_MODZ.LFCPC.COMBAT_'],
                           # '*MODZ.ZSVC.gct': ['weave', '_LEVEL5_MODZ.ZSVC_'],
                           # '*MODZ.LFCVC.gct': ['weave', '_LEVEL5_MODZ.LFCVC_'],
                           # '*MODZ.ZSVC.COMBAT.gct': ['weave', '_LEVEL5_MODZ.ZSVC.COMBAT_'],
                           # '*MODZ.LFCVC.COMBAT.gct': ['weave', '_LEVEL5_MODZ.LFCVC.COMBAT_']
                           }

    data_dict = {}

    for key in search_pattern_dict:
        if args.aggregate_out:
            if search_pattern_dict[key][0] == "weave":
                path = os.path.join(args.proj_dir, args.search_pattern, search_pattern_dict[key][0], key)
            else:
                path = os.path.join(args.proj_dir, args.search_pattern, search_pattern_dict[key][0], '*', key)
        else:
            path = os.path.join(args.proj_dir, search_pattern_dict[key][0],
                            args.search_pattern,key)

        out_path = os.path.join(args.build_folder, args.cohort_name + search_pattern_dict[key][1])

        if not os.path.exists(os.path.join(args.proj_dir, search_pattern_dict[key][0])):
            continue

        logger.info("working on {}".format(path))
        if 'MODZ' in key:
            data, _ = build(path, out_path, '.gctx', cut=False)
        elif 'NORM' in key:
            data, failure_list = build(path, out_path, '.gctx', cut=True, check_size=True)
        else:
            data, _ = build(path, out_path, '.gctx', cut=True)
        data_dict[key] = data

    if data_dict.has_key('*NORM.gct'):
        mk_inst_info(data_dict['*MEDIAN.gct'], data_dict['*NORM.gct'], args)
    else:
        mk_inst_info(data_dict['*MEDIAN.gct'], args=args)

    mk_sig_info(search_pattern_dict, data_dict, args)

    try:
        mk_cell_metadata(args, failure_list)
    except Exception as e:
        mk_cell_metadata(args)

if __name__ == "__main__":
    args = build_parser().parse_args(sys.argv[1:])
    setup_logger.setup(verbose=args.verbose)

    logger.debug("args:  {}".format(args))

    main(args)

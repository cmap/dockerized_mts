import pandas as pd


def flag_instances(mfi: pd.DataFrame, thresholds: dict = None):
    """
    Flags instances based on a quality control metric for 'count'.

    :param mfi: DataFrame containing level 3 data with counts.
    :param thresholds: Dictionary of quality control thresholds.
                       Defaults to {'count': 20} if not specified.
    :return: List of flagged instance_ids based on the 'count' metric.
    """
    # Set default thresholds if none are provided
    if thresholds is None:
        thresholds = {'count': 25}

    # Check if required columns are present in the DataFrame
    if not all(col in mfi.columns for col in ['profile_id', 'ccle_name', 'count']):
        raise ValueError("df must have 'profile_id', 'ccle_name', and 'count' columns")

    # Create a copy to avoid modifying the original DataFrame
    df = mfi.copy()

    # Flag instances based on 'count'
    inst_count_flag_df = df.loc[df['count'] < thresholds['count']][['instance_id','count']].rename(columns={'count':'instance_count'}) # TODO: this will become a db table
    lst_inst_count_flag = list(inst_count_flag_df.instance_id.unique())

    return lst_inst_count_flag


def flag_wells(mfi: pd.DataFrame, thresholds: dict = None):
    """
    Flag instances based on quality control metrics.

    :param mfi: DataFrame containing level 3 data with counts.
    :param thresholds: Dictionary of quality control thresholds. These should contain
                       a threshold for the median count across analytes in a well and
                       the median logMFI value for control analytes 1-10.
    :return: Tuple of lists containing flagged instance_ids for each QC metric.
    """
    # Set default thresholds if none are provided
    if thresholds is None:
        thresholds = {'mcount': 25, 'ctl_mmfi': 8}

    # Check if required columns are present in the DataFrame
    required_columns = ['profile_id', 'ccle_name', 'count', 'logMFI']
    if not all(col in mfi.columns for col in required_columns):
        raise ValueError(f"DataFrame must have {', '.join(required_columns)} columns")

    # Create a copy to avoid modifying the original DataFrame
    mfi = mfi.copy()

    # Flag instances based on 'count'
    count_grouped_df = \
    mfi.groupby(['profile_id']).median(numeric_only=True).reset_index().rename(columns={'count': 'well_count'})[
        ['profile_id', 'well_count']]
    flagged_counts_df = count_grouped_df.loc[count_grouped_df['well_count'] < thresholds['mcount']]
    flagged_counts = flagged_counts_df.profile_id.unique()
    lst_well_count_flag = list(mfi.loc[mfi.profile_id.isin(flagged_counts)].instance_id.unique())

    # Flag instances based on 'ctl_mmfi'
    mmfi_grouped_df = mfi[mfi.ccle_name == 'prism invariant 5'].groupby(
        ['profile_id']).median(numeric_only=True).reset_index().rename(columns={'logMFI': 'cbc5_mfi'})[
        ['profile_id', 'cbc5_mfi']]
    flagged_ctl_df = mmfi_grouped_df.loc[mmfi_grouped_df['cbc5_mfi'] < thresholds['ctl_mmfi']][
        ['profile_id', 'cbc5_mfi']]
    flagged_ctl = flagged_ctl_df.profile_id.unique()
    lst_well_ctl_flag = list(mfi.loc[mfi.profile_id.isin(flagged_ctl)].instance_id.unique())

    # Create qc dataframe for addition to db
    well_qc_df = count_grouped_df.merge(mmfi_grouped_df, on='profile_id')  # TODO: this will become a db table

    return lst_well_count_flag, lst_well_ctl_flag


def flag_cell_lines(mfi: pd.DataFrame, qc_table: pd.DataFrame, thresholds: dict = None) -> tuple:
    """
    Flag instances based on quality control metrics.

    :param mfi: DataFrame containing level 3 data.
    :param qc_table: DataFrame containing quality control data.
    :param thresholds: Dictionary of quality control thresholds.

    :return: Tuple of lists containing flagged instance_ids for each QC metric.
    """
    if thresholds is None:
        thresholds = {'dr': 1.8, 'er': 0.05, 'ctl_md': 6}

    if not all(col in mfi.columns for col in ['profile_id', 'ccle_name', 'prism_replicate']):
        raise ValueError("df must have 'profile_id', 'ccle_name', and 'prism_replicate' columns")

    if not all(col in qc_table.columns for col in ['ccle_name', 'dr', 'error_rate', 'ctl_vehicle_md']):
        raise ValueError("qc_table must have 'ccle_name', 'dr', 'error_rate', and 'ctl_vehicle_md' columns")

    # Create identifiers
    mfi = mfi.copy()
    qc_table = qc_table.copy()
    mfi['cell_plate'] = mfi['ccle_name'] + ':' + mfi['prism_replicate']
    qc_table['cell_plate'] = qc_table['ccle_name'] + ':' + qc_table['prism_replicate']

    # Find instances to flag based on thresholds
    flagged_dr = qc_table.loc[qc_table.dr < thresholds['dr']].cell_plate.unique()
    flagged_er = qc_table.loc[qc_table.error_rate > thresholds['er']].cell_plate.unique()
    flagged_md = qc_table.loc[qc_table.ctl_vehicle_md < thresholds['ctl_md']].cell_plate.unique()

    lst_dr = mfi.loc[mfi.cell_plate.isin(flagged_dr)].instance_id.unique()
    lst_er = mfi.loc[mfi.cell_plate.isin(flagged_er)].instance_id.unique()
    lst_md = mfi.loc[mfi.cell_plate.isin(flagged_md)].instance_id.unique()

    return lst_dr, lst_er, lst_md


def generate_flag_df(mfi: pd.DataFrame, qc_table: pd.DataFrame, thresholds: dict = None) -> pd.DataFrame:
    """
  Generate a DataFrame with instance_ids and their corresponding error flags.

  :param mfi: DataFrame containing level 3 data with bead count.
  :param qc_table: DataFrame of qc table.
  :param thresholds: Dictionary of quality control thresholds.
  :return: DataFrame with columns 'instance_id' and 'error_flag'.
  """

    # Run your flagging functions
    lst_inst_count_flag = flag_instances(mfi, thresholds)
    lst_well_count_flag, lst_well_ctl_flag = flag_wells(mfi, thresholds)
    lst_dr, lst_er, lst_md = flag_cell_lines(mfi, qc_table, thresholds)

    # Assign unique numeric identifiers to each type of error
    error_flags = {
        'inst_count_flag': 1,
        'well_count_flag': 2,
        'well_ctl_flag': 3,
        'dr': 4,
        'er': 5,
        'md': 6
    }

    error_desc = {
        1: 'Low count for a single cell line',
        2: 'Low count across well',
        3: 'Low control signal in well',
        4: 'Low dynamic range for cell line in plate',
        5: 'High error rate for cell line in plate',
        6: 'Low vehicle median for cell line in plate'
    }

    # Create a list of tuples (instance_id, error_flag)
    all_flags = []
    for instance_id in lst_inst_count_flag:
        all_flags.append((instance_id, error_flags['inst_count_flag'], error_desc[1]))
    for instance_id in lst_well_count_flag:
        all_flags.append((instance_id, error_flags['well_count_flag'], error_desc[2]))
    for instance_id in lst_well_ctl_flag:
        all_flags.append((instance_id, error_flags['well_ctl_flag'], error_desc[3]))
    for instance_id in lst_dr:
        all_flags.append((instance_id, error_flags['dr'], error_desc[4]))
    for instance_id in lst_er:
        all_flags.append((instance_id, error_flags['er'], error_desc[5]))
    for instance_id in lst_md:
        all_flags.append((instance_id, error_flags['md'], error_desc[6]))

        # Convert list of tuples
    df_flags = pd.DataFrame(all_flags, columns=['instance_id', 'error_code', 'error_desc'])

    return df_flags


def parse_instance_id(x: str):
    x.split('_')[0]

#!/usr/bin/env bash

# read in flagged arguments
while getopts ":d:c:m:" arg; do
  case $arg in
    d) # specify input folder (plate level)
      data_dir=${OPTARG};;
    c) # compound name (ID or file name same string)
      compound=${OPTARG};;
    m) # path to metadata about lineage and mutations
      meta_path=${OPTARG}
  esac
done

export HDF5_USE_FILE_LOCKING=FALSE

echo "${data_dir}" "${compound}" "${meta_path}"

Rscript /render_reports.R -d "${data_dir}" -c "${compound}" -m "${meta_path}"

exit_code=$?

echo "$exit_code"
exit $exit_code

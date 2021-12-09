#!/usr/bin/env bash

# read in flagged arguments
while getopts ":d:" arg; do
  case $arg in
    d) # specify input folder (project level)
      data_dir=${OPTARG};;
  esac
done

export HDF5_USE_FILE_LOCKING=FALSE

echo "${data_dir}"

Rscript /render_reports.R -d "${data_dir}"

exit_code=$?

echo "$exit_code"
exit $exit_code

#!/usr/bin/env bash

# read in flagged arguments
while getopts ":d:o:n:" arg; do
  case $arg in
    d) # specify input folder
      data_dir=${OPTARG};;
    o) # specifcy output folder
      output_dir=${OPTARG};;
    n) # specifcy output folder
      screen_name=${OPTARG};;
  esac
done

chmod +x /render_reports.R
export HDF5_USE_FILE_LOCKING=FALSE
echo "${data_dir}" "${output_dir}" "${screen_name}"
Rscript /render_reports.R -d "${data_dir}" -o "${output_dir}" -n "${screen_name}"

exit_code=$?

echo "$exit_code"
exit $exit_code

#!/usr/bin/env bash

# read in flagged arguments
while getopts ":b:o:n:" arg; do
  case $arg in
    b) # specify input folder
      data_dir=${OPTARG};;
    o) # specifcy output folder
      output_dir=${OPTARG};;
    n) # specify build name
      build_name=${OPTARG}
  esac
done

chmod +x /qc.R
chmod +x /src/qc_functions.R
export HDF5_USE_FILE_LOCKING=FALSE
echo "${data_dir}" "${output_dir}" "${build_name}"
Rscript /qc.R -b "${data_dir}" -o "${output_dir}" -n "${build_name}"

exit_code=$?

echo "$exit_code"
exit $exit_code

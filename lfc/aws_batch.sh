#!/bin/bash

# read in flagged arguments
while getopts ":b:o:" arg; do
  case $arg in
    b) # specify input folder
      data_dir=${OPTARG};;
    o) # specifcy output folder
      output_dir=${OPTARG};;
  esac
done

chmod +x /calc_lfc.R
chmod +x /src/lfc_functions.R
export HDF5_USE_FILE_LOCKING=FALSE
echo "${data_dir}" "${output_dir}" "${calc_gr}"
Rscript /calc_lfc.R -b "${data_dir}" -o "${output_dir}"

exit_code=$?

echo "$exit_code"
exit $exit_code

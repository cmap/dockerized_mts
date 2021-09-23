#!/bin/bash

# read in flagged arguments
while getopts ":b:o:a:" arg; do
  case $arg in
    b) # specify input folder
      data_dir=${OPTARG};;
    o) # specifcy output folder
      output_dir=${OPTARG};;
    a) # specify assay/build (PR300 or PR500)
      assay=${OPTARG}
  esac
done

chmod +x /normalize.R
chmod +x /src/normalization_functions.R
export HDF5_USE_FILE_LOCKING=FALSE
echo "${data_dir}" "${output_dir}" "${assay}"
Rscript /normalize.R -b "${data_dir}" -o "${output_dir}" -a "${assay}"

exit_code=$?

echo "$exit_code"
exit $exit_code

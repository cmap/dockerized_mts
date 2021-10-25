#!/bin/bash

# read in flagged arguments
while getopts ":b:o:a:n:" arg; do
  case $arg in
    b) # specify input folder
      data_dir=${OPTARG};;
    o) # specifcy output folder
      output_dir=${OPTARG};;
    a) # specify assay/build (PR300 or PR500)
      assay=${OPTARG}
    n) # specify build name
      build_name=${OPTARG}};;
  esac
done

chmod +x /normalize.R
chmod +x /src/normalization_functions.R
export HDF5_USE_FILE_LOCKING=FALSE
echo "${data_dir}" "${output_dir}" "${assay}" "${build_name}"
Rscript /normalize.R -b "${data_dir}" -o "${output_dir}" -a "${assay}" -n "${build_name}"

exit_code=$?

echo "$exit_code"
exit $exit_code

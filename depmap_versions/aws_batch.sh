#!/usr/bin/env bash

# read in flagged arguments
while getopts ":p:o:" arg; do
  case $arg in
    p) # specify project folder
      project_dir=${OPTARG};;
    o) # specifcy output folder
      output_dir=${OPTARG};;
  esac
done

chmod +x /make_matrices.R
chmod +x /src/depmap_functions.R
export HDF5_USE_FILE_LOCKING=FALSE
echo "${project_dir_dir}" "${output_dir}"
Rscript /make_matrices.R -p "${data_dir}" -o "${output_dir}"

exit_code=$?

echo "$exit_code"
exit $exit_code

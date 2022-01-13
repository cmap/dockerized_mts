#!/usr/bin/env bash

# read in flagged arguments
while getopts ":p:o:n:" arg; do
  case $arg in
    p) # specify project folder
      project_dir=${OPTARG};;
    o) # specifcy output folder
      output_dir=${OPTARG};;
    n) # specifcy build name
      build_name=${OPTARG};;
  esac
done

chmod +x /make_matrices.R
chmod +x /src/depmap_functions.R
export HDF5_USE_FILE_LOCKING=FALSE
echo "${project_dir}" "${output_dir}" "${build_name}"
Rscript /make_matrices.R -p "${project_dir}" -o "${output_dir}" -n "${build_name}"

exit_code=$?

echo "$exit_code"
exit $exit_code

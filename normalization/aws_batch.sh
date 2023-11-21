#!/usr/bin/env bash

# read in flagged arguments
while getopts ":b:o:a:n:c:" arg; do
  case $arg in
    b) # specify input folder
      data_dir=${OPTARG};;
    o) # specifcy output folder
      output_dir=${OPTARG};;
    a) # specifcy output folder
      assay=${OPTARG};;
    n) # specify build nam e
      build_name=${OPTARG};;
    c) # query clue API
      api_call=${OPTARG};;
  esac
done

chmod +x /normalize.R
chmod +x /src/normalization_functions.R
export HDF5_USE_FILE_LOCKING=FALSE
echo "${data_dir}" "${output_dir}" "${assay}" "${build_name}" "${api_call}"

args=(
  -b "${data_dir}"
  -o "${output_dir}"
  -a "${assay}"
  -n "${build_name}"
  -c "TRUE"
)

if [[ ! -z $exclude ]]
then
  args+=(-x "${exclude}")
fi

Rscript /normalize.R "${args[@]}"

exit_code=$?

echo "$exit_code"
exit $exit_code

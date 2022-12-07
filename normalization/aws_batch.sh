#!/usr/bin/env bash

# read in flagged arguments
while getopts ":b:o:a:n:" arg; do
  case $arg in
    b) # specify input folder
      data_dir=${OPTARG};;
    o) # specifcy output folder
      output_dir=${OPTARG};;
    a) # specifcy output folder
      assay=${OPTARG};;
    n) # specify build nam e
      build_name=${OPTARG};;
    x) # comma-sep list of ctl barcode_ids
      exclude=${OPTARG}
  esac
done

chmod +x /normalize.R
chmod +x /src/normalization_functions.R
export HDF5_USE_FILE_LOCKING=FALSE
echo "${data_dir}" "${output_dir}" "${assay}" "${build_name}"

args=(
  -b "${data_dir}"
  -o "${output_dir}"
  -a "${assay}"
  -n "${build_name}"
)

if [[ ! -z $exclude ]]
then
  args+=(-x "${exclude}")
fi

Rscript /normalize.R "${args[@]}"

exit_code=$?

echo "$exit_code"
exit $exit_code

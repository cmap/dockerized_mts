#!/bin/bash

# read in flagged arguments
while getopts ":i:o:" arg; do
  case $arg in
    i) # specify input folder
      data_dir=${OPTARG};;
    o) # specifcy output folder
      output_dir=${OPTARG};;
  esac
done

batch_index=${AWS_BATCH_JOB_ARRAY_INDEX}
chmod +x /drc_compound.R
chmod +x /src/drc_functions.R
echo "${data_dir}" "${output_dir}"
Rscript /drc_compound.R -i "${data_dir}" -o "${output_dir}"

exit_code=$?

echo "$exit_code"
exit $exit_code

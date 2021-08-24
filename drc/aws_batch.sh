#!/bin/bash

# read in flagged arguments
while getopts ":i:o:g:" arg; do
  case $arg in
    i) # specify input folder
      data_dir=${OPTARG};;
    o) # specifcy output folder
      output_dir=${OPTARG};;
    g) # specify assay/build (PR300 or PR500)
      calc_gr=${OPTARG}
  esac
done

IFS=',' read -r -a a_projects <<< "${projects}"
batch_index=${AWS_BATCH_JOB_ARRAY_INDEX}
chmod +x /drc_compound.R
chmod +x /src/MTS_functions.R
pert_name=$(echo "${projects}" | jq -r --argjson index ${batch_index} '.[$index].pert_name')
project=$(echo "${projects}" | jq -r --argjson index ${batch_index} '.[$index].project_id')
plate=$(echo "${projects}" | jq -r --argjson index ${batch_index} '.[$index].compound_plate')
mult=$(echo "${projects}" | jq -r --argjson index ${batch_index} '.[$index].multiple_plates')
echo "${data_dir}" "${output_dir}" "${project}" "${pert_name}" "${plate}"
Rscript /drc_compound.R "${data_dir}" "${output_dir}" "${project}" "${pert_name}" "${plate}" "${mult}" "${calc_gr}"

exit_code=$?

echo "$exit_code"
exit $exit_code

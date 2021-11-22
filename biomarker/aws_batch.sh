#!/bin/bash

# read in flagged arguments
while getopts ":b:o:d:" arg; do
  case $arg in
    b) # specify input folder
      data_dir=${OPTARG};;
    o) # specifcy output folder
      output_dir=${OPTARG};;
    d) # specify directory with -omics data
      biomarker_dir=${OPTARG};;
  esac
done

chmod +x /biomarkers.R
chmod +x /src/biomarker_functions.R
export HDF5_USE_FILE_LOCKING=FALSE
echo "${data_dir}" "${output_dir}" "${biomarker_dir}"

if [[ ! -z $projects ]]
then
    IFS=',' read -r -a a_projects <<< "${projects}"
    batch_index=${AWS_BATCH_JOB_ARRAY_INDEX}
    pert_id=$(echo "${projects}" | jq -r --argjson index ${batch_index} '.[$index].pert_id')
    project=$(echo "${projects}" | jq -r --argjson index ${batch_index} '.[$index].x_project_id')
    plate=$(echo "${projects}" | jq -r --argjson index ${batch_index} '.[$index].pert_plate')
    cleaned_pert_id=$(echo "${pert_id//|/$'_'}")
    sanitized_pert_id="${cleaned_pert_id^^}"
    data_dir="${data_dir}"/"${project}"/"${plate}"/"${sanitized_pert_id}"
    output_dir="${output_dir}"/"${project}"/"${plate}"/"${sanitized_pert_id}"
fi
echo "${data_dir}" "${output_dir}" "${biomarker_dir}" "${qc_table}"
Rscript /biomarkers.R -b "${data_dir}" -o "${output_dir}" -d "${biomarker_dir}"

exit_code=$?

echo "$exit_code"
exit $exit_code

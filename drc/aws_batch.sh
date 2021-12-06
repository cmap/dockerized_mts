#!/usr/bin/env bash

# read in flagged arguments
while getopts ":i:o:f:" arg; do
  case $arg in
    i) # specify input folder
      data_dir=${OPTARG};;
    o) # specifcy output folder
      output_dir=${OPTARG};;
    f)
      projects=${OPTARG};;
  esac
done

out="${output_dir}"
data="${data_dir}"
echo "${data}" "${out}"

batch_index=0
if [[ ! -z "${AWS_BATCH_JOB_ARRAY_INDEX}" ]]
then
  batch_index=${AWS_BATCH_JOB_ARRAY_INDEX}
fi

if [[ ! -z $projects ]]
then
    pert_id=$(cat "${projects}" | jq -r --argjson index ${batch_index} '.[$index].pert_id')
    project=$(cat "${projects}" | jq -r --argjson index ${batch_index} '.[$index].x_project_id')
    plate=$(cat "${projects}" | jq -r --argjson index ${batch_index} '.[$index].pert_plate')
    cleaned_pert_id=$(echo "${pert_id//|/$'_'}")
    sanitized_pert_id="${cleaned_pert_id^^}"
    data="${data_dir}"/"${project}"/"${plate}"/"${sanitized_pert_id}"
    out="${output_dir}"/"${project}"/"${plate}"/"${sanitized_pert_id}"
fi

echo "${data}" "${out}"
if [[ "$pert_id" == "DMSO" ]]
then
  echo "Skipping DMSO"
else
  Rscript /drc_compound.R -i "${data}" -o "${out}"
fi

exit_code=$?
echo "$exit_code"
exit $exit_code

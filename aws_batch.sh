#!/bin/bash

# read in flagged arguments
while getopts ":t:i:o:a:" arg; do
  case $arg in
    t) # is this the data processing step (0 or 1)
      type=${OPTARG};;
    i) # specify input folder
      data_dir=${OPTARG};;
    o) # specifcy output folder
      output_dir=${OPTARG};;
    a) # specify assay/build (PR300 or PR500)
      assay=${OPTARG}
  esac
done

if [ "$type" == "1" ] ; then
  IFS=',' read -r -a a_projects <<< "${projects}"
  batch_index=${AWS_BATCH_JOB_ARRAY_INDEX}
  chmod +x /drc_compound.R
  chmod +x /src/MTS_functions.R
  pert_name=$(echo "${projects}" | jq -r --argjson index ${batch_index} '.[$index].pert_name')
  project=$(echo "${projects}" | jq -r --argjson index ${batch_index} '.[$index].project_id')
  echo "${data_dir}" "${output_dir}" "${project}" "${pert_name}"
  Rscript /drc_compound.R "${data_dir}" "${output_dir}" "${project}" "${pert_name}" "0"
elif [ "$type" == "2" ] ; then
  chmod +x /calc_lfc.R
  chmod +x /src/MTS_functions.R
  export HDF5_USE_FILE_LOCKING=FALSE
  echo "${data_dir}" "${output_dir}" "${assay}"
  Rscript /calc_lfc.R "${data_dir}" "${output_dir}" "${assay}"
else
  chmod +x /pre_processing.R
  chmod +x /src/MTS_functions.R
  export HDF5_USE_FILE_LOCKING=FALSE
  echo "${data_dir}" "${output_dir}" "${assay}" "${project_key}"
  Rscript /pre_processing.R "${data_dir}" "${output_dir}" "${assay}"
fi

exit_code=$?

echo "$exit_code"
exit $exit_code

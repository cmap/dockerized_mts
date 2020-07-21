#!/bin/bash

# read in flagged arguments
while getopts ":i:o:p:a:" arg; do
  case $arg in
    i) # specify input folder
      data_dir=${OPTARG}
      ;;
    o) # specifcy output folder
      output_dir=${OPTARG}
      ;;
    p) # specify the directory holding project_key.csv
      project_key_dir=${OPTARG}
      ;;
    a) # specify assay/build (PR300 or PR500)
      assay=${OPTARG}
  esac
done

IFS=',' read -r -a a_projects <<< "${projects}"
batch_index=${AWS_BATCH_JOB_ARRAY_INDEX}
project="${a_projects[${batch_index}]}"
chmod +x /MTS_Data_Processing.R
chmod +x /src/MTS_functions.R
Rscript /MTS_Data_Processing.R "${data_dir}" "${output_dir}" "${project}" "${assay}" "${project_key_dir}"

exit_code=$?

echo "$exit_code"
exit $exit_code
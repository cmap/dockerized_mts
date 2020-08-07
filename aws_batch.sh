#!/bin/bash

# read in flagged arguments
while getopts ":d:i:o:p:a:" arg; do
  case $arg in
    d) # is this the data processing step (0 or 1)
      type=${OPTARG};;
    i) # specify input folder
      data_dir=${OPTARG};;
    o) # specifcy output folder
      output_dir=${OPTARG};;
    p) # specify the directory holding project_key.csv
      project_key=${OPTARG};;
    a) # specify assay/build (PR300 or PR500)
      assay=${OPTARG}
  esac
done

if [ "$type" == "1" ] ; then
  IFS=',' read -r -a a_projects <<< "${projects}"
  batch_index=${AWS_BATCH_JOB_ARRAY_INDEX}
  project="${a_projects[${batch_index}]}"
  chmod +x /data_processing.R
  chmod +x /src/MTS_functions.R
  export HDF5_USE_FILE_LOCKING=FALSE
  Rscript /data_processing.R "${data_dir}" "${output_dir}" "${project}" "${assay}"
else
  batch_index=${AWS_BATCH_JOB_ARRAY_INDEX}
  chmod +x /pre_processing.R
  chmod +x /src/MTS_functions.R
  export HDF5_USE_FILE_LOCKING=FALSE
  Rscript /pre_processing.R "${data_dir}" "${output_dir}" "${assay}" "${project_key}"
fi

exit_code=$?

echo "$exit_code"
exit $exit_code

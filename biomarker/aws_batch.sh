#!/bin/bash

# read in flagged arguments
while test $# -gt 0; do
  case "$1" in
    -h| --help)
      Rscript /biomarkers.R --help
      exit 0
      ;;
    -b| --base_dir)
      shift
      base_dir=$1
      ;;
    -o| --out)
      shift
      out_dir=$1
      ;;
    -d| --biomarker_dir)
      shift
      biomarker_dir=$1
      ;;
    -f| --file)
      shift
      biomarker_file=$1
      ;;
    -q| --qc_file)
      shift
      qc_file=$1
      ;;
    *)
      printf "Unknown parameter: %s \n" "$1"
      shift
      ;;
  esac
  shift
done

chmod +x /biomarkers.R
chmod +x /src/biomarker_functions.R
export HDF5_USE_FILE_LOCKING=FALSE

if [[ ! -z $projects ]]
then
    IFS=',' read -r -a a_projects <<< "${projects}"
    batch_index=${AWS_BATCH_JOB_ARRAY_INDEX}
    pert_id=$(echo "${projects}" | jq -r --argjson index ${batch_index} '.[$index].pert_id')
    project=$(echo "${projects}" | jq -r --argjson index ${batch_index} '.[$index].x_project_id')
    plate=$(echo "${projects}" | jq -r --argjson index ${batch_index} '.[$index].pert_plate')
    biomarker_file=$(echo "${projects}" | jq -r --argjson index ${batch_index} '.[$index].feature')
    cleaned_pert_id=$(echo "${pert_id//|/$'_'}")
    sanitized_pert_id="${cleaned_pert_id^^}"
    base_dir="${base_dir}"/"${project}"/"${plate}"/"${sanitized_pert_id}"
    out_dir="${out_dir}"/"${project}"/"${plate}"/"${sanitized_pert_id}"
fi

echo "${base_dir}" "${out_dir}" "${biomarker_dir}" "${biomarker_file}" "${qc_file}"

args=(
  -b "${base_dir}"
  -o "${out_dir}"
  -d "${biomarker_dir}"
)

if [[ ! -z $biomarker_file ]]
then
  args+=(-f "${biomarker_file}")
fi

if [[ ! -z $qc_file ]]
then
  args+=(-q "${qc_file}")
fi

Rscript /biomarkers.R "${args[@]}"

exit_code=$?

echo "$exit_code"
exit $exit_code

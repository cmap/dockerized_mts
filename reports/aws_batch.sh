#!/usr/bin/env bash
# read in flagged arguments
while test $# -gt 0; do
  case "$1" in
    -f| --compound_key_path)
      shift
      projects=$1
      ;;
    -d| --data_dir)
      shift
      data_dir=$1
      ;;
    -c| --compound)
      shift
      compound=$1
      ;;
    -m| --meta)
      shift
      meta_path=$1
      ;;
    -b| --combination)
      shift
      combination=$1
      ;;
    -q| --qc_path)
      shift
      qc_path=$1
      ;;
    *)
      printf "Unknown parameter: %s \n" "$1"
      shift
      exit 1
      ;;
  esac
  shift
done

combination=${combination:-0}
echo $combination

batch_index=0
sanitized_pert_id=""
if [[ ! -z $projects ]]
then
    if [[ ! -z "${AWS_BATCH_JOB_ARRAY_INDEX}" ]]; then
      batch_index=${AWS_BATCH_JOB_ARRAY_INDEX}
    fi
    pert_id=$(cat "${projects}" | jq -r --argjson index ${batch_index} '.[$index].pert_id')
    project=$(cat "${projects}" | jq -r --argjson index ${batch_index} '.[$index].x_project_id')
    plate=$(cat "${projects}" | jq -r --argjson index ${batch_index} '.[$index].pert_plate')
    cleaned_pert_id=$(echo "${pert_id//|/$'_'}")
    sanitized_pert_id="${cleaned_pert_id^^}"
    data_dir="${data_dir}"/"${project,,}"/"${project^^}"/"${plate}"/"${sanitized_pert_id}"
    compound="${sanitized_pert_id}"
    SUB='|'
    if [[ "$pert_id" == *"$SUB"* ]]; then
      combination=1
    fi
fi

echo "${data_dir}" "${compound}" "${meta_path}" "${combination}"

args=(
  -d "${data_dir}"
  -c "${compound}"
  -m "${meta_path}"
  -q "${qc_path}"
  -b "${combination}"
)

if [[ "$sanitized_pert_id" == "DMSO" ]]
then
  echo "Skipping DMSO"
else
  Rscript /render_reports.R "${args[@]}"
fi


exit_code=$?

echo "$exit_code"
exit $exit_code

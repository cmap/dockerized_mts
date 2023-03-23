#!/usr/bin/env bash
# read in flagged arguments
while test $# -gt 0; do
  case "$1" in
    -f| --compound_key_path)
      shift
      compound_key=$1
      ;;
    -d| --data_dir)
      shift
      data_dir=$1
      ;;
    -o| --out)
      shift
      out=$1
      ;;
    -c| --compound)
      shift
      compound=$1
      ;;
    -s| --screen)
      shift
      screen=$1
      ;;
    -pp| --pert_plate)
      shift
      plate=$1
      ;;
    -pj| --project)
      shift
      project=$1
      ;;
    *)
      printf "Unknown parameter: %s \n" "$1"
      shift
      exit 1
      ;;
  esac
  shift
done

batch_index=0
sanitized_pert_id=""
if [[ ! -z $compound_key ]]
then
    if [[ ! -z "${AWS_BATCH_JOB_ARRAY_INDEX}" ]]; then
      batch_index=${AWS_BATCH_JOB_ARRAY_INDEX}
    fi
    pert_id=$(cat "${compound_key}" | jq -r --argjson index ${batch_index} '.[$index].pert_id')
    project=$(cat "${compound_key}" | jq -r --argjson index ${batch_index} '.[$index].x_project_id')
    plate=$(cat "${compound_key}" | jq -r --argjson index ${batch_index} '.[$index].pert_plate')
    cleaned_pert_id=$(echo "${pert_id//|/$'_'}")
    sanitized_pert_id="${cleaned_pert_id^^}"
    project_dir="${data_dir}"/"${project,,}"/"${project^^}"
    data_dir="${project_dir}"/"${plate}"/"${sanitized_pert_id}"
    compound="${sanitized_pert_id}"

    #output format for s3://portal-data.prism.org/data-to-load/
    out="${out}"/"${screen}"/"${project^^}"/"${plate}"/"${sanitized_pert_id}"/
fi

args=(
  --data_dir "${data_dir}"
  --out "${out}"
  --screen "${screen}"
  --pert_plate "${plate}"
  --pert_id "${compound}"
  --project "${project}"
)

#setup environment
source activate prism

echo python /clue/bin/prep_portal_data.py  "${args[@]}"
python /clue/bin/prep_portal_data.py  "${args[@]}"


exit_code=$?
echo "$exit_code"
exit $exit_code

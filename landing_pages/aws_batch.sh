#!/usr/bin/env bash
# read in flagged arguments
while test $# -gt 0; do
  case "$1" in
    -d| --data_dir)
      shift
      data_dir=$1
      ;;
    -o| --out)
      shift
      out_dir=$1
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
if [[ ! -z $projects ]]
then
    if [[ ! -z "${AWS_BATCH_JOB_ARRAY_INDEX}" ]]; then
      batch_index=${AWS_BATCH_JOB_ARRAY_INDEX}
    fi
    project=$(cat "${projects}" | jq -r --argjson index ${batch_index} '.[$index].x_project_id')
    data_dir="${data_dir}"/"${project,,}"/"${project^^}"
    out_dir="${out_dir}"/"${project,,}"
fi

echo "${data_dir}" "${out_dir}"

if [[ ! -d $out_dir ]]
then
  mkdir -p $out_dir
fi

args=(
  -d "${data_dir}"
  -o "${out_dir}"
)

Rscript /render_reports.R "${args[@]}"

exit_code=$?

echo "$exit_code"
exit $exit_code

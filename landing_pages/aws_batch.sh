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
    -o| --out)
      shift
      out_dir=$1
      ;;
    -p| --project_name)
      shift
      project_name=$1
      ;;
    -l| --val_link)
      shift
      val_link=$1
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
    val_link=$(find "${out_dir}" -type d -name "*validation_compounds" -execdir basename '{}' ';')
    val_link=./"${val_link}"/index.html
    out_dir="${out_dir}"/"${project,,}"
    project_name="${project^^}"
fi

echo "${data_dir}" "${out_dir}" "${project_name}" "${val_link}"

if [[ ! -d $out_dir ]]
then
  mkdir -p $out_dir
fi

args=(
  -d "${data_dir}"
  -o "${out_dir}"
  -p "${project_name}"
  -l "${val_link}"
)

Rscript /render_reports.R "${args[@]}"

exit_code=$?

echo "$exit_code"
exit $exit_code

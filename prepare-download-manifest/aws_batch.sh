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
    -b| --build_name)
      shift
      build_name=$1
      ;;
    -bc| --no_batch_correct)
      shift
      no_batch_correct="TRUE"
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
if [[ ! -z $projects ]]
then
    if [[ ! -z "${AWS_BATCH_JOB_ARRAY_INDEX}" ]]; then
      batch_index=${AWS_BATCH_JOB_ARRAY_INDEX}
    fi
    project=$(cat "${projects}" | jq -r --argjson index ${batch_index} '.[$index].x_project_id')
    combination=$(cat "${projects}" | jq -r --argjson index ${batch_index} '.[$index].combination_project')
    data_dir="${data_dir}"/"${project,,}"/"${project^^}"
    out_dir="${out_dir}"/"${project,,}"
    project_name="${project^^}"
fi

echo "${data_dir}" "${out_dir}" "${project_name}"

if [[ ! -d $out_dir ]]
then
  mkdir -p $out_dir
fi

args=(
  -d "${data_dir}"
  -o "${out_dir}"
  -p "${project_name}"
  -b "${build_name}"
)


if [[ ${combination} != "0" ]]
then
  args+=(--combination)
fi


if [[ -n ${no_batch_correct} ]]
then
  args+=( --no_batch_correct )
fi

echo Rscript /prepare_downloads_manifest.R "${args[@]}"
Rscript /prepare_downloads_manifest.R "${args[@]}"

exit_code=$?

echo "$exit_code"
exit $exit_code

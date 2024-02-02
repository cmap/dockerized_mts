#!/usr/bin/env bash
# read in flagged arguments
while test $# -gt 0; do
  case "$1" in
    -f| --compound_key_path)
      shift
      projects=$1
      ;;
    -p| --project_dir)
      shift
      project_dir=$1
      ;;
    -n| --build_name)
      shift
      build_name=$1
      ;;
    -o| --output_dir)
      shift
      output_dir=$1
      ;;
    -lp| --lfc_pattern)
      shift
      lfc_pattern=$1
      ;;
    -lc| --lfc_column)
      shift
      lfc_column=$1
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
if [[ ! -z $projects ]]
then
    if [[ ! -z "${AWS_BATCH_JOB_ARRAY_INDEX}" ]]; then
      batch_index=${AWS_BATCH_JOB_ARRAY_INDEX}
    fi
    project=$(cat "${projects}" | jq -r --argjson index ${batch_index} '.[$index].x_project_id')
    project_dir="${project_dir}"/"${project,,}"/"${project^^}"/data/
    build_name="${project^^}"
    output_dir="${project_dir}"
fi

echo "${project_dir}" "${output_dir}" "${build_name}"

args=(
  -p "${project_dir}"
  -o "${output_dir}"
  -n "${build_name}"
)


if [[ ! -z $lfc_pattern ]]
then
  args+=(-lp "${lfc_pattern}")
fi

if [[ ! -z $lfc_column ]]
then
  args+=(-lc "${lfc_column}")
fi

if [[ "$sanitized_pert_id" == "DMSO" ]]
then
  echo "Skipping DMSO"
else
  Rscript /make_matrices.R "${args[@]}"
fi


exit_code=$?

echo "$exit_code"
exit $exit_code

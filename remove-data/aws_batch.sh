#!/bin/bash

# Loop through arguments and assign them to environment variables
# Arguments are expected to be in the form of '--key value'
# For example, '--data-dir /data'
#for ((i = 1; i <= $#; i++)); do
#    # Get the key and value
#    key=${!i}
#    if [[ $key == --* ]]; then
#        # Remove leading '--' and replace '-' with '_' for the environment variable name
#        env_var=${key/--/}
#        env_var=$(echo $env_var | tr '-' '_' | tr '[:lower:]' '[:upper:]')
#
#        # Get the value which is the next argument
#        let "i++"
#        value=${!i}
#
#        # Assign the value to the environment variable
#        export $env_var="$value"
#    fi
#done

source activate prism

args=()
while test $# -gt 0; do
  case "$1" in
    -h| --help)
      shift
      python /clue/bin/remove_data.py  "${args[@]}"
      exit 0
      ;;
    -f| --compound_key_path)
      shift
      compound_key=$1
      ;;
    -d| --data_dir)
      shift
      data_dir=$1
      ;;
    -s| --search_patterns)
      shift
      args+=(--search_patterns "$1")
      ;;
    -i| --ignore-missing-fields)
      shift
      args+=("--ignore-missing-fields")
      ;;
    -fd| --field)
      shift
      args+=(--field $1)
      ;;
    -vl| --value)
      shift
      args+=(--value $1)
      ;;
    -o| --out)
      shift
      args+=(--out $1)
      ;;
    -v| --verbose)
      shift
      args+=(--verbose)
      ;;
    *)
      printf "Unknown parameter: %s \n" "$1"
      shift
      exit 1
      ;;
  esac
  shift
done

#if [ -n "$COMPOUND_KEY_PATH" ]; then
#  compound_key=$COMPOUND_KEY_PATH
#fi

batch_index=0
sanitized_pert_id=""
if [[ ! -z $compound_key ]]
then
    if [[ -n "${AWS_BATCH_JOB_ARRAY_INDEX}" ]]; then
      if [[ -n $RERUN_INDEX ]]; then
          echo "RERUN_INDEX:" "${RERUN_INDEX}"
          batch_index=${RERUN_INDEX}
        else
          echo "AWS_BATCH_JOB_ARRAY_INDEX:" "$AWS_BATCH_JOB_ARRAY_INDEX"
          batch_index=${AWS_BATCH_JOB_ARRAY_INDEX}
        fi
    fi
    pert_id=$(cat "${compound_key}" | jq -r --argjson index ${batch_index} '.[$index].pert_id')
    project=$(cat "${compound_key}" | jq -r --argjson index ${batch_index} '.[$index].x_project_id')
    plate=$(cat "${compound_key}" | jq -r --argjson index ${batch_index} '.[$index].pert_plate')
    cleaned_pert_id=$(echo "${pert_id//|/$'_'}")
    sanitized_pert_id="${cleaned_pert_id^^}"
    project_dir="${data_dir}"/"${project,,}"/"${project^^}"
    data_dir="${project_dir}"/"${plate}"/"${sanitized_pert_id}"
    compound="${sanitized_pert_id}"
fi

echo "${data_dir}" "${compound}" "${meta_path}" "${combination}"

args+=(--data_dir ${data_dir})


echo python /clue/bin/remove_data.py  "${args[@]}"
python /clue/bin/remove_data.py  "${args[@]}"

exit_code=$?
echo "$exit_code"
exit $exit_code

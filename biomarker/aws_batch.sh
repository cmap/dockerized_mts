#!/usr/bin/env bash

# read in flagged arguments
while test $# -gt 0; do
  case "$1" in
    -h| --help)
      Rscript /biomarkers.R --help
      exit 0
      ;;
    -c| --compound_key_path)
      shift
      projects=$1
      ;;
    -b| --base_dir)
      shift
      base_dir=$1
      ;;
    -o| --out)
      shift
      out_dir=$1
      ;;
    -s | --project_key_start_index)
      shift
      PROJECT_KEY_START_INDEX=$1
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
    -i| --failed_indicies)
      shift
      FAILED_INDICES=$1
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

echo FAILED_INDICES: "$FAILED_INDICES"
#Case: Multiple Failed Jobs run from rerun-script as array job of size: n_failed_jobs
if [[ -n "${AWS_BATCH_JOB_ARRAY_INDEX}" && -n $FAILED_INDICES ]]; then # -n is same as ! -z
  #Case: Multiple Failed Jobs run from rerun-script as array job of size: n_failed_jobs
  IFS=',' read -r -a failed_indices <<< "${FAILED_INDICES}"
  RERUN_INDEX="${failed_indices[${AWS_BATCH_JOB_ARRAY_INDEX}]}"
  echo "RERUN_INDEX IS: ${RERUN_INDEX}"
elif [[ -n "$FAILED_INDICES" ]]; then
    #case: Single failed job, cloned job and passed as parameter from command UI in AWS
    IFS=',' read -r -a failed_indices <<< "${FAILED_INDICES}"
    RERUN_INDEX="${failed_indices[0]}"
    echo "RERUN_INDEX IS: ${RERUN_INDEX}"
fi


batch_index=0
if [[ -n $projects ]]
then
    if [[ -n "${AWS_BATCH_JOB_ARRAY_INDEX}" ]]; then
        echo "PROJECT_KEY_START_INDEX:" "$PROJECT_KEY_START_INDEX"
        if [[ -n $RERUN_INDEX ]]; then
          echo "RERUN_INDEX:" "${RERUN_INDEX}"
          batch_index=$(($PROJECT_KEY_START_INDEX + ${RERUN_INDEX}))
        else
          echo "AWS_BATCH_JOB_ARRAY_INDEX:" "$AWS_BATCH_JOB_ARRAY_INDEX"
          batch_index=$(($PROJECT_KEY_START_INDEX + ${AWS_BATCH_JOB_ARRAY_INDEX}))
        fi
        echo "BATCH INDEX:" $batch_index
    fi
    pert_id=$(cat "${projects}" | jq -r --argjson index ${batch_index} '.[$index].pert_id')
    project=$(cat "${projects}" | jq -r --argjson index ${batch_index} '.[$index].x_project_id')
    plate=$(cat "${projects}" | jq -r --argjson index ${batch_index} '.[$index].pert_plate')
    biomarker_file=$(cat "${projects}" | jq -r --argjson index ${batch_index} '.[$index].feature')
    cleaned_pert_id=$(echo "${pert_id//|/$'_'}")
    sanitized_pert_id="${cleaned_pert_id^^}"
    base_dir="${base_dir}"/"${project,,}"/"${project^^}"/"${plate}"/"${sanitized_pert_id}"
    out_dir="${out_dir}"/"${project,,}"/"${project^^}"/"${plate}"/"${sanitized_pert_id}"/biomarker
fi

echo "${base_dir}" "${out_dir}" "${biomarker_dir}" "${biomarker_file}" "${qc_file}"

args=(
  -b "${base_dir}"
  -o "${out_dir}"
)

if [[ ! -z $biomarker_dir ]]
then
  args+=(-d "${biomarker_dir}")
fi

if [[ ! -z $biomarker_file ]]
then
  args+=(-f "${biomarker_file}")
fi

if [[ ! -z $qc_file ]]
then
  args+=(-q "${qc_file}")
fi

if [[ "$pert_id" == "DMSO" ]]
then
    echo "Skipping DMSO"
else
    echo Rscript /biomarkers.R "${args[@]}"
    Rscript /biomarkers.R "${args[@]}"
fi

exit_code=$?

echo "$exit_code"
exit $exit_code

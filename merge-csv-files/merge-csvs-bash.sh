#!/usr/bin/env bash
#setup environment
source activate merino

cd /cmap/merino/
python setup.py develop

#return to /
cd /

#optional
if test $# -lt 1; then
  python /clue/bin/merge_csvs.py --help
  exit 1
fi

while test $# -gt 0; do
  case "$1" in
    -h|--help)
      python /clue/bin/merge_csvs.py --help
      exit 0
      ;;
    -f|--compound_key_path)
      shift
      projects=$1
      ;;
    -d|--data_dir)
      shift
      DATA_DIR=$1
      ;;
    -o|--out)
      shift
      OUT_DIR=$1
      ;;
    -s|--search_pattern)
      shift
      PATTERN=$1
      ;;
    -sp|--separator)
      shift
      SEPARATOR=$1
      ;;
    -ap|--add_project_name)
      shift
      ADD_PROJECT_NAME=true
      ;;
    -v|--verbose)
      shift
      VERBOSE=true
      ;;
    *)
      printf "Unknown parameter: %s \n" "$1"
      shift
      ;;
  esac
  shift
done



batch_index=0
if [[ ! -z "${AWS_BATCH_JOB_ARRAY_INDEX}" ]]; then
  batch_index=${AWS_BATCH_JOB_ARRAY_INDEX}
fi

if [[ ! -z $projects ]]
then
    PROJECT=$(cat "${projects}" | jq -r --argjson index ${batch_index} '.[$index].x_project_id')
    PATTERN=$(cat "${projects}" | jq -r --argjson index ${batch_index} '.[$index].pattern')

    if [[ $projects == *_proj_search_pattern.json ]] # * is used for pattern matching
    then
        DATA_DIR="${DATA_DIR}"/"${PROJECT,,}"/"${PROJECT^^}"
        OUT_DIR="${OUT_DIR}"/"${PROJECT,,}"/"${PROJECT^^}"/data
        ADD_PROJECT_NAME=true
    else
        PERT=$(cat "${projects}" | jq -r --argjson index ${batch_index} '.[$index].pert_id')
        PERT_PLATE=$(cat "${projects}" | jq -r --argjson index ${batch_index} '.[$index].pert_plate')
        cleaned_pert_id=$(echo "${PERT//|/$'_'}")
        sanitized_pert_id="${cleaned_pert_id^^}"
        DATA_DIR="${DATA_DIR}"/"${PROJECT,,}"/"${PROJECT^^}"/"${PERT_PLATE}"/"${sanitized_pert_id}"/biomarker
        OUT_DIR="${OUT_DIR}"/"${PROJECT,,}"/"${PROJECT^^}"/"${PERT_PLATE}"/"${sanitized_pert_id}"
    fi
fi

if [[ ! -d $OUT_DIR ]]
then
  mkdir -p $OUT_DIR
fi

args=(
  -d "$DATA_DIR"
  -o "$OUT_DIR"
  -s "$PATTERN"
)

if [[ ! -z $ADD_PROJECT_NAME ]]
then
  args+=(-ap)
fi

echo "${DATA_DIR}" "${OUT_DIR}" "${PATTERN}"
if [[ ! -z $VERBOSE ]]
then
  args+=(-v)
fi

if [[ ! -z $SEPARTOR ]]
then
  args+=(
    -sp "$SEPARATOR"
  )
fi

if [[ "$pert_id" == "DMSO" ]]
then
  echo "Skipping DMSO"
else
  python /clue/bin/merge_csvs.py "${args[@]}"
fi


exit_code=$?
conda deactivate
exit $exit_code

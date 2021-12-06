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
    -f| --compound_key_path)
      shift
      projects=$1
      ;;
    -d| --data_dir)
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
    -v| --verbose)
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

if [[ ! -d $OUT_DIR ]]
then
  mkdir -p $OUT_DIR
fi

batch_index=0
if [[ ! -z "${AWS_BATCH_JOB_ARRAY_INDEX}" ]]; then
  batch_index=${AWS_BATCH_JOB_ARRAY_INDEX}
fi

if [[ ! -z $projects ]]
then
    PERT=$(cat "${projects}" | jq -r --argjson index ${batch_index} '.[$index].pert_id')
    PROJECT=$(cat "${projects}" | jq -r --argjson index ${batch_index} '.[$index].x_project_id')
    PERT_PLATE=$(cat "${projects}" | jq -r --argjson index ${batch_index} '.[$index].pert_plate')
    PATTERN=$(cat "${projects}" | jq -r --argjson index ${batch_index} '.[$index].pattern')
    cleaned_pert_id=$(echo "${PERT//|/$'_'}")
    sanitized_pert_id="${cleaned_pert_id^^}"
    DATA_DIR="${DATA_DIR}"/"${PROJECT}"/"${PERT_PLATE}"/"${sanitized_pert_id}"/biomarker
    OUT_DIR="${OUT_DIR}"/"${PROJECT}"/"${PERT_PLATE}"/"${sanitized_pert_id}"
fi

args=(
  -d "$DATA_DIR"
  -o "$OUT_DIR"
  -s "$PATTERN"
)

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

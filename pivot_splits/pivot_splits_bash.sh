#!/usr/bin/env bash

#setup environment
source activate prism

cd /cmap/merino/
python setup.py develop

#return to /
cd /

#optional
if test $# -lt 1; then
  python /clue/bin/pivot_splits.py --help
  exit 1
fi

while test $# -gt 0; do
  case "$1" in
    -h|--help)
      python /clue/bin/pivot_splits.py --help
      exit 0
      ;;
    -f| --compound_key_path)
      shift
      projects=$1
      ;;
    -d| --splits_dir)
      shift
      SPLITS_DIR=$1
      ;;
    -p| --pert)
      shift
      PERT=$1
      ;;
    -pr| --project)
      shift
      PROJECT=$1
      ;;
    -pp| --pert_plate)
      shift
      PERT_PLATE=$1
      ;;
    -o|--out)
      shift
      BUILD_DIR=$1
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

batch_index=0

if [[ ! -z $projects ]]
then
    if [[ ! -z "${AWS_BATCH_JOB_ARRAY_INDEX}" ]]; then
      batch_index=${AWS_BATCH_JOB_ARRAY_INDEX}
    fi
    PERT=$(cat "${projects}" | jq -r --argjson index ${batch_index} '.[$index].pert_id')
    PROJECT=$(cat "${projects}" | jq -r --argjson index ${batch_index} '.[$index].x_project_id')
    PERT_PLATE=$(cat "${projects}" | jq -r --argjson index ${batch_index} '.[$index].pert_plate')
    cleaned_pert_id=$(echo "${PERT//|/$'_'}")
    sanitized_pert_id="${cleaned_pert_id^^}"
    SPLITS_DIR="${SPLITS_DIR}"/"${PROJECT,,}"
    PROJECT=${PROJECT^^} #enforcing uppercase
fi

if [[ ! -d $SPLITS_DIR ]]
then
  mkdir -p ${SPLITS_DIR}
fi

args=(
  -d "$SPLITS_DIR"
)

if [[ ! -z $VERBOSE ]]
then
  args+=(-v)
fi

if [[ ! -z $PROJECT || ! -z $PERT_PLATE || ! -z $PERT ]]
then
  args+=(
    -p "$PERT"
    -pr "$PROJECT"
    -pp "$PERT_PLATE"
  )
fi

if [[ "$PERT" == "DMSO" ]]
then
  echo "Skipping DMSO"
else
  python /clue/bin/pivot_splits.py "${args[@]}"
fi


exit_code=$?
conda deactivate
exit $exit_code

#!/bin/bash
#setup environment
source activate merino

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

if [ ! -d $BUILD_DIR ]
then
  mkdir -p $BUILD_DIR
fi

if [[ ! -z $projects ]]
then
    IFS=',' read -r -a a_projects <<< "${projects}"
    batch_index=${AWS_BATCH_JOB_ARRAY_INDEX}
    PERT=$(echo "${projects}" | jq -r --argjson index ${batch_index} '.[$index].pert_id')
    PROJECT=$(echo "${projects}" | jq -r --argjson index ${batch_index} '.[$index].x_project_id')
    PERT_PLATE=$(echo "${projects}" | jq -r --argjson index ${batch_index} '.[$index].pert_plate')
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

python /clue/bin/pivot_splits.py "${args[@]}"

exit_code=$?
conda deactivate
exit $exit_code

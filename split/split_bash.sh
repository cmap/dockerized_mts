#!/bin/bash
#setup environment
source activate merino

cd /cmap/merino/
python setup.py develop

#return to /
cd /

#optional
if test $# -lt 1; then
  python /clue/bin/split.py --help
  exit 1
fi

while test $# -gt 0; do
  case "$1" in
    -h|--help)
      python /clue/bin/split.py --help
      exit 0
      ;;
    -b| --build_path)
      shift
      BUILD_PATH=$1
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
batch_index=0
if [[ ! -z "${AWS_BATCH_JOB_ARRAY_INDEX}" ]]; then
  batch_index=${AWS_BATCH_JOB_ARRAY_INDEX}
fi

if [[ ! -z $projects ]]
then
    IFS=',' read -r -a a_projects <<< "${projects}"
    PERT=$(echo "${projects}" | jq -r --argjson index ${batch_index} '.[$index].pert_id')
    PROJECT=$(echo "${projects}" | jq -r --argjson index ${batch_index} '.[$index].x_project_id')
    PERT_PLATE=$(echo "${projects}" | jq -r --argjson index ${batch_index} '.[$index].pert_plate')
fi


args=(
  -b "$BUILD_PATH"
  -o "$BUILD_DIR"
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

python /clue/bin/split.py "${args[@]}"

exit_code=$?
conda deactivate
exit $exit_code

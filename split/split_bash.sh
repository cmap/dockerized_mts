#!/usr/bin/env bash
#setup environment
source activate prism

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
    -f| --compound_key_path)
      shift
      projects=$1
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
    -sp|--search_patterns)
      shift
      SEARCH_PATTERNS=$1
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
if [[ ! -z "${AWS_BATCH_JOB_ARRAY_INDEX}" ]]; then
  batch_index=${AWS_BATCH_JOB_ARRAY_INDEX}

fi

if [[ ! -z $projects ]]
then
    PERT=$(cat "${projects}" | jq -r --argjson index ${batch_index} '.[$index].pert_id')
    PROJECT=$(cat "${projects}" | jq -r --argjson index ${batch_index} '.[$index].x_project_id')
    BUILD_DIR="${BUILD_DIR}"/"${PROJECT,,}"
    PERT_PLATE=$(cat "${projects}" | jq -r --argjson index ${batch_index} '.[$index].pert_plate')
    PROJECT=${PROJECT^^} #enforcing uppercase
fi

if [ ! -d $BUILD_DIR ]
then
  mkdir -p $BUILD_DIR
fi

args=(
  -b "$BUILD_PATH"
  -o "$BUILD_DIR"
)

#add verbose for logging on AWS
if [[ ! -z $VERBOSE || ! -z "${AWS_BATCH_JOB_ARRAY_INDEX}" ]]
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

if [[ ! -z $SEARCH_PATTERNS ]]
then
  args+=(
    -sp "$SEARCH_PATTERNS"
  )
fi

if [[ "$PERT" == "DMSO" ]]
then
   echo "Skipping DMSO"
else
  echo python /clue/bin/split.py "${args[@]}"
  python /clue/bin/split.py "${args[@]}"
fi



exit_code=$?
conda deactivate
exit $exit_code

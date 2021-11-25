#!/bin/bash

#setup environment
source activate merino
cd /cmap/merino/
python setup.py develop

#return to /
cd /

print_help () {
  python /clue/bin/deal.py --help
}

#optional
if test $# -lt 1; then
  print_help
  exit 1
fi

while test $# -gt 0; do
  case "$1" in
    -h|--help)
      print_help
      exit 0
      ;;
    -b| --build_path)
      shift
      BUILD_PATH=$1
      ;;
    -p| --project)
      shift
      PROJECT=$1
      ;;
    -k|--only_keys)
      shift
      KEYS=$1
      ;;
    -s|--sig_id_cols)
      shift
      SIG_ID_COLS=$1
      ;;
    -o|--out)
      shift
      OUT_DIR=$1
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

if [ ! -d $OUT_DIR ]
then
  mkdir -p $OUT_DIR
fi

##Run Collate
if [[ -z $BUILD_PATH || -z $OUT_DIR ]]
then
  printf "Required arguments missing\n"
  exit -1
fi

args=(
  -b "$BUILD_PATH"
  -o "$OUT_DIR"
)

if [[ ! -z $VERBOSE ]]
then
  args+=(-v)
fi

if [[ ! -z $PROJECT ]]
then
  args+=(-p $PROJECT)
fi


if [[ -z "${AWS_BATCH_JOB_ARRAY_INDEX}" ]]; then
    if [[ ! -z $KEYS ]]
    then
      args+=(-k $KEYS)
    fi

    if [[ ! -z $SIG_ID_COLS ]]
    then
      args+=(-s $SIG_ID_COLS)
    fi
    batch=0
else
    batch=${AWS_BATCH_JOB_ARRAY_INDEX}
fi

if [[ ! -z $projects ]]
then
    IFS=',' read -r -a a_projects <<< "${projects}"
    PROJECT=$(echo "${projects}" | jq -r --argjson index ${batch} '.[$index].x_project_id')
    KEY=$(echo "${projects}" | jq -r --argjson index ${batch} '.[$index].level')
    args+=(-p "$PROJECT")
    args+=(-k "$KEY")
    python /clue/bin/deal.py "${args[@]}"
else
    python /clue/bin/deal.py "${args[@]}"
fi

exit_code=$?
conda deactivate
exit $exit_code

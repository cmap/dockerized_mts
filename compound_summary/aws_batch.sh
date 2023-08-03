#!/usr/bin/env bash

#setup environment
source activate prism
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
    -f| --compound_key_path)
      shift
      projects=$1
      ;;
    -d| --data_path)
      shift
      DATA_PATH=$1
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



##Run Collate
if [[ -z $DATA_PATH || -z $OUT_DIR ]]
then
  printf "Required arguments missing\n"
  exit -1
fi

args=(
  -b "$DATA_PATH"
)

if [[ -z "${AWS_BATCH_JOB_ARRAY_INDEX}" ]]; then
    batch=0
else
    batch=${AWS_BATCH_JOB_ARRAY_INDEX}
fi

if [[ ! -z $projects ]]
then
    PROJECT=$(cat "${projects}" | jq -r --argjson index ${batch} '.[$index].x_project_id')
    PROJECT_DIR="${OUT_DIR}"/"${PROJECT,,}"
    OUT_DIR="${OUT_DIR}"/"${PROJECT,,}"
    args+=(-i "$PROJECT_DIR")
    args+=(-o "$OUT_DIR")
fi

if [ ! -d $OUT_DIR ]
then
  mkdir -p $OUT_DIR
fi


if [[ ! -z $VERBOSE ]]
then
  args+=(-v)
fi


python /clue/bin/deal.py "${args[@]}"

exit_code=$?
conda deactivate
exit $exit_code

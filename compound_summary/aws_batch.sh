#!/usr/bin/env bash

#return to /
cd /

print_help () {
  Rscript /compound_summary.R --help
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
    -i| --data_path)
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



if [[ -z "${AWS_BATCH_JOB_ARRAY_INDEX}" ]]; then
    batch=0
else
    batch=${AWS_BATCH_JOB_ARRAY_INDEX}
fi

PROJECT_DIR="${DATA_PATH}"

if [[ ! -z $projects ]]
then
    PROJECT=$(cat "${projects}" | jq -r --argjson index ${batch} '.[$index].x_project_id')
    PROJECT_DIR="${DATA_PATH}"/"${PROJECT,,}"/"${PROJECT^^}"/data/
    OUT_DIR="${OUT_DIR}"/"${PROJECT,,}"/"${PROJECT^^}"/data/
fi

args=(
  -i "$PROJECT_DIR"
  -o "$OUT_DIR"
)

if [ ! -d $OUT_DIR ]
then
  mkdir -p $OUT_DIR
fi


if [[ ! -z $VERBOSE ]]
then
  args+=(-v)
fi

echo Rscript /compound_summary.R "${args[@]}"
Rscript /compound_summary.R "${args[@]}"

exit_code=$?
exit $exit_code

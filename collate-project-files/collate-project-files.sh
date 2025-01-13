#!/usr/bin/env bash
#setup environment
source activate prism

cd /cmap/merino/
python setup.py develop

#return to /
cd /

print_help () {
  python /clue/bin/collate-project-files.py --help
  echo "  -spl, --search_pattern_list - comma separated list of search patterns in DRC, e.g. 'DRC_TABLE*,discrete_associations*' (bash)"
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
    -pf|--project_key_path)
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
    -n|--filename)
      shift
      OUT_FILE=$1
      ;;
    -p|--file_prefix)
      shift
      FILE_PREFIX=$1
      ;;
    -spl|--search_pattern_list)
      shift
      SEARCH_PATTERN_LIST=$1
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

args=()
if [[ ! -z $projects ]]
then
    PROJECT=$(cat "${projects}" | jq -r --argjson index ${batch_index} '.[$index].x_project_id')
    SCREEN=$(cat "${projects}" | jq -r --argjson index ${batch_index} '.[$index].screen')
    DATA_DIR="${DATA_DIR}"/"${PROJECT,,}"/"${PROJECT^^}/*/*/"
    OUT_DIR="${OUT_DIR}"/"${PROJECT,,}"/"${PROJECT^^}"/data
    ADD_PROJECT_NAME=true
fi

if [[ ! -d $OUT_DIR ]]
then
  mkdir -p $OUT_DIR
fi

args+=(
  -d "$DATA_DIR"
  -o "$OUT_DIR"
  --project "$PROJECT"
  --screen "$SCREEN"
)

if [[ ! -z $ADD_PROJECT_NAME ]]
then
  args+=(-ap)
fi

echo "${DATA_DIR}" "${OUT_DIR}"
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

if [[ ! -z $SEARCH_PATTERN_LIST ]]
then
  IFS=',' read -r -a array <<< "$SEARCH_PATTERN_LIST"
  if [[ ! -z $FILE_PREFIX ]]
  then
    args+=(
      -p "$FILE_PREFIX"
    )
  fi
  for pattern in "${array[@]}"
  do
    echo python /clue/bin/collate-project-files.py "${args[@]}" -s "$pattern"
    python /clue/bin/collate-project-files.py "${args[@]}" -s "$pattern"
  done
else
  echo "Need to provide search pattern list"
  exit 1
fi

exit_code=$?
conda deactivate
exit $exit_code

#!/usr/bin/env bash
#setup environment
source activate prism

#return to /
cd /

print_help () {
  python /clue/bin/eps-prep.py --help
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
    DATA_DIR="${DATA_DIR}"/"${PROJECT,,}"/"${PROJECT^^}"
fi


args+=(
  -d "$DATA_DIR"
)

python /clue/bin/eps-prep.py "${args[@]}"

exit_code=$?
conda deactivate
exit $exit_code

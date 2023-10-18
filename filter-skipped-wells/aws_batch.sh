#!/usr/bin/env bash
source activate prism

print_help () {
  python /clue/bin/filter_skipped_wells.py --help
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
    -d| --data_dir)
      shift
      DATA_DIR=$1
      ;;
    *)
      printf "Unknown parameter: %s \n" "$1"
      shift
      ;;
  esac
  shift
done

if [[ -z $DATA_DIR ]]
then
  printf "Required arguments missing\n"
  exit -1
fi

args=(
  -d "$DATA_DIR"
)
python /clue/bin/filter_skipped_wells.py "${args[@]}"

exit_code=$?

echo "$exit_code"
exit $exit_code
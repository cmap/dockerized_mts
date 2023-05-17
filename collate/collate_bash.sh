#!/usr/bin/env bash

print_help () {
  printf "Usage ./collate_bash.sh [options]\nOptions include:\n"
  printf -- "\t-pd, --proj_dir \t Path to the pod directory, assemble should be subfolder (required) \n"
  printf -- "\t-bd, --build_dir \t Output folder for build files (required) \n"
  printf -- "\t-cn, --cohort_name \t String designating the prefix to each build file (required)\n"
  printf -- "\t-sp, --search_pattern \t Search string in proj_dir, only run matching plates, default is wildcard '*' \n"
  printf -- "\t-x, --exclude_bcids \t Barcode Ids to include (LUAS or CTLBC) as comma-separated string. Default is none \n"
  printf -- "\t-v, --verbose \t\t Verbose flag, print additional output \n"
  printf -- "\t-h, --help \t\t Print this help text\n"
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
    -pd| --proj_dir)
      shift
      PROJ_DIR=$1
      ;;
    -bd|--build_dir)
      shift
      BUILD_DIR=$1
      ;;
    -cn| --cohort_name)
      shift
      COHORT_NAME=$1
      ;;
    -sp| --search_pattern)
      shift
      SEARCH_PATTERN=$1
      ;;
    -x| --exclude_bcids)
      shift
      EXCLUDE_BCIDS=$1
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

##Run Collate

if [[ -z $PROJ_DIR || -z $BUILD_DIR || -z $COHORT_NAME ]]
then
  printf "Required arguments missing\n"
  exit -1
fi

args=(
  -pd "$PROJ_DIR"
  -bd "$BUILD_DIR"
  -cn "$COHORT_NAME"
)


if [[ ! -z $SEARCH_PATTERN ]]
then
  args+=(-sp "$SEARCH_PATTERN")
fi

if [[ ! -z $EXCLUDE_BCIDS ]]
then
  args+=(-x "$EXCLUDE_BCIDS")
fi

if [[ ! -z $VERBOSE ]]
then
  args+=(-v)
fi

#setup environment
source activate merino
cd /cmap
git clone https://github.com/cmap/merino.git
cd /cmap/merino/
python setup.py develop 

#return to /
cd / 

#echo python collate.py "${args[@]}"
python /clue/bin/collate.py "${args[@]}"
exit_code=$?

source deactivate
exit $exit_code

#!/bin/bash

print_help () {
  printf "Usage ./stack_build [options]\nOptions include:\n"
  printf -- "\t-b, --build_paths \t Comma separated list of build paths to collate (required) \n"
  printf -- "\t-n, --build_name \t String designating the prefix to each build file (required)\n"
  printf -- "\t-k, --only_stack_keys \t Comma separated list of keys. Useful if parallelizing, only listed keys will be concatenated \n"
  printf -- "\t-o, --out \t Output folder for build files (required) \n"
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
    -b| --build_paths)
      shift
      BUILD_PATHS=$1
      ;;
    -k|--only_stack_keys)
      shift
      KEYS=$1
      ;;
    -o|--out)
      shift
      BUILD_DIR=$1
      ;;
    -n| --build_name)
      shift
      BUILD_NAME=$1
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

if [[ -z $BUILD_PATHS || -z $BUILD_DIR || -z $BUILD_NAME ]]
then
  printf "Required arguments missing\n"
  exit -1
fi

args=(
  -b "$BUILD_PATHS"
  -n "$BUILD_NAME"
  -o "$BUILD_DIR"
)

if [[ ! -z $VERBOSE ]]
then
  args+=(-v)
fi

if [[ ! -z $KEYS ]]
then
  args+=(-k $KEYS)
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
python /clue/bin/stack.py "${args[@]}"
exit_code=$?

conda deactivate
exit $exit_code

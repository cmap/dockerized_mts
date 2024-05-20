#!/usr/bin/env bash

print_help () {
  printf "Usage ./stack_build [options]\nOptions include:\n"
  printf -- "\t-b, --build_paths \t Comma separated list of build paths to collate (required) \n"
  printf -- "\t-n, --build_name \t String designating the prefix to each build file (required)\n"
  printf -- "\t-k, --only_stack_keys \t Comma separated list of keys. Useful if parallelizing, only listed keys will be concatenated \n"
  printf -- "\t-s, --sig_id_cols \t Comma separated list of col names to create sig_ids if not present \n"
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
    -s|--sig_id_cols)
      shift
      SIG_ID_COLS=$1
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


#setup environment
source activate prism
cd /cmap/merino/
python setup.py develop

#return to /
cd /

if [[ -z "${AWS_BATCH_JOB_ARRAY_INDEX}" ]]; then
    if [[ ! -z $KEYS ]]
    then
      args+=(-k $KEYS)
    fi

    if [[ ! -z $SIG_ID_COLS ]]
    then
      args+=(-s $SIG_ID_COLS)
    fi

    python /clue/bin/stack.py "${args[@]}"
else
    batch=${AWS_BATCH_JOB_ARRAY_INDEX}
    if [[ ! -z $KEYS ]]
    then
      # number of child jobs needs to match length of keys
      IFS=',' read -r -a keys <<< "${KEYS}"
      batch=${AWS_BATCH_JOB_ARRAY_INDEX}
      KEY="${keys[${batch}]}"
      args+=(-k $KEY)
    else
        if [[ $batch = "0" ]]; then
            args+=(-k 'inst_info')
        elif [[ $batch = "1" ]]; then
            args+=(-k 'cell_info')
        elif [[ $batch = "2" ]]; then
            args+=(-k 'QC_TABLE')
        elif [[ $batch = "3" ]]; then
            args+=(-k 'compound_key')
        elif [[ $batch = "4" ]]; then
            args+=(-k 'LEVEL2_COUNT')
        elif [[ $batch = "5" ]]; then
            args+=(-k 'LEVEL2_MFI')
        elif [[ $batch = "6" ]]; then
            args+=(-k 'LEVEL3_LMFI')
        elif [[ $batch = "7" ]]; then
            args+=(-k 'LEVEL4_LFC')
        elif [[ $batch = "8" ]]; then
            args+=(-k 'LEVEL5_LFC')
            if [[ ! -z $SIG_ID_COLS ]]
            then
              args+=(-s $SIG_ID_COLS)
            fi
        else
            echo "Done"
        fi
    fi
    echo python /clue/bin/stack.py "${args[@]}"
    python /clue/bin/stack.py "${args[@]}"
fi
exit_code=$?
conda deactivate
exit $exit_code
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

    python /clue/bin/deal.py "${args[@]}"
else
    batch=${AWS_BATCH_JOB_ARRAY_INDEX}
    if [[ $batch = "0" ]]; then
        args+=(-k 'inst_info')
        python /clue/bin/deal.py "${args[@]}"
    elif [[ $batch = "1" ]]; then
        args+=(-k 'cell_info')
        python /clue/bin/deal.py "${args[@]}"
    elif [[ $batch = "2" ]]; then
        args+=(-k 'QC_table')
        python /clue/bin/deal.py "${args[@]}"
    elif [[ $batch = "3" ]]; then
        args+=(-k 'compound_key')
        python /clue/bin/deal.py "${args[@]}"
    elif [[ $batch = "4" ]]; then
        args+=(-k 'LEVEL2_COUNT')
        python /clue/bin/deal.py "${args[@]}"
    elif [[ $batch = "5" ]]; then
        args+=(-k 'LEVEL2_MFI')
        python /clue/bin/deal.py "${args[@]}"
    elif [[ $batch = "6" ]]; then
        args+=(-k 'LEVEL3_LMFI')
        python /clue/bin/deal.py "${args[@]}"
    elif [[ $batch = "7" ]]; then
        args+=(-k 'LEVEL4_LFC')
        python /clue/bin/deal.py "${args[@]}"
    elif [[ $batch = "8" ]]; then
        args+=(-k 'LEVEL5_LFC')
        if [[ ! -z $SIG_ID_COLS ]]
        then
          args+=(-s $SIG_ID_COLS)
        fi
        python /clue/bin/deal.py "${args[@]}"
    else
        echo "Done"
    fi
fi
exit_code=$?
conda deactivate
exit $exit_code

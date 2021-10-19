#!/bin/bash

#optional 
if test $# -lt 1; then
  printf "Usage ./extract_biomarker_bash.sh [options]\nOptions include:\n"
  printf -- "\t-f, --file_name \t Path to the continous association file (required) \n"
  printf -- "\t-o, --out_dir \t Output folder for top 10 files (required) \n"
  printf -- "\t-ds, --default_dataset \t Default dataset name if dataset column does not exist in continous_association file \n"
  printf -- "\t-h, --help \t\t Print this help text\n"
  exit 1
fi

while test $# -gt 0; do
  case "$1" in
    -h|--help)
      printf "Usage ./extract_biomarker_bash.sh [options]\nOptions include:\n"
      printf -- "\t-f, --file_name \t Path to the continous association file (required) \n"
      printf -- "\t-o, --out_dir \t Output folder for top 10 files (required) \n"
      printf -- "\t-ds, --default_dataset \t Default dataset name if dataset column does not exist in continous_association file \n"
      printf -- "\t-h, --help \t\t Print this help text\n"
      exit 0
      ;;
    -f| --file_name)
      shift
      FILE_NAME=$1
      ;;
    -o| --out_dir)
      shift
      OUT_DIR=$1
      ;;
    -ds| --default_dataset)
      shift
      DEFAULT_DATASET=$1
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

##Run Top 10 biomarker

if [[ -z $FILE_NAME || -z $OUT_DIR ]]
then
  printf "Required arguments missing\n"
  exit -1
fi

args=(
  -f "$FILE_NAME"
  -o "$OUT_DIR"
)
if [[ ! -z $DEFAULT_DATASET ]]
then
  args+=(-ds "$DEFAULT_DATASET")
fi

if [[ ! -z $VERBOSE ]]
then
  args+=(-v)
fi

#return to /
cd / 

#echo python extract_biomarker.py "${args[@]}"
python /clue/bin/extract_biomarker.py "${args[@]}"

#!/bin/bash

#optional 
if test $# -lt 1; then
      printf "Usage ./extract_biomarker_bash.sh [options]\nOptions include:\n"
      printf -- "\t-d, --data_dir \t Path to the continuous association folder (required) \n"
      printf -- "\t-o, --out_dir \t Output folder for top 10 files (required) \n"\
      printf -- "\t-x, --extract_top_x \t The number of top biomarkers to extract from file (defaults to 10) \n"
      printf -- "\t-h, --help \t\t Print this help text\n"
      exit 1
fi

while test $# -gt 0; do
  case "$1" in
    -h|--help)
      printf "Usage ./extract_biomarker_bash.sh [options]\nOptions include:\n"
      printf -- "\t-d, --data_dir \t Path to the continuous association folder (required) \n"
      printf -- "\t-o, --out_dir \t Output folder for top X files (required) \n"
      printf -- "\t-x, --extract_top_x \t The number of top biomarkers to extract from file (defaults to 10) \n"
      printf -- "\t-h, --help \t\t Print this help text\n"
      exit 0
      ;;
    -d| --data_dir)
      shift
      DATA_DIR=$1
      ;;
    -f| --compound_key_path)
      shift
      projects=$1
      ;;
    -o| --out_dir)
      shift
      OUT_DIR=$1
      ;;
    -x| --extract_top_x)
      shift
      TOP_X=$1
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

##Extract Top X biomarkers, defaults to 10
if [[ -z $TOP_X ]]
then
  TOP_X=10
fi

if [[ -z $DATA_DIR || -z $OUT_DIR ]]
then
  printf "Required arguments missing\n"
  exit -1
fi



#return to /
cd / 

#If this is an array job set batch_index
if [[ -z "${AWS_BATCH_JOB_ARRAY_INDEX}" ]]; then
    batch_index=0
else
    batch_index=${AWS_BATCH_JOB_ARRAY_INDEX}
fi

if [[ ! -z $projects ]]
then
    pert_id=$(echo "${projects}" | jq -r --argjson index ${batch_index} '.[$index].pert_id')
    project=$(echo "${projects}" | jq -r --argjson index ${batch_index} '.[$index].x_project_id')
    plate=$(echo "${projects}" | jq -r --argjson index ${batch_index} '.[$index].pert_plate')
    cleaned_pert_id=$(echo "${pert_id//|/$'_'}")
    sanitized_pert_id="${cleaned_pert_id^^}"
    DATA_DIR="${DATA_DIR}"/"${project}"/"${plate}"/"${sanitized_pert_id}"/continuous_associations.csv
    OUT_DIR="${OUT_DIR}"/"${project}"/"${plate}"/"${sanitized_pert_id}"
fi

args=(
  -d "$DATA_DIR"
  -o "$OUT_DIR"
  -x "$TOP_X"
)

if [[ ! -z $VERBOSE ]]
then
  args+=(-v)
fi
echo -d "${DATA_DIR}" -o "${OUT_DIR}" -x "${TOP_X}"
python /clue/bin/extract_biomarker.py "${args[@]}"

exit_code=$?
exit $exit_code
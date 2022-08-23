#!/usr/bin/env bash
print_help () {
  source activate merino
  cd /cmap/merino/
  python setup.py develop
  python /cmap/merino/merino/assemble/assemble.py --help
}

while test $# -gt 0; do
  case "$1" in
    -h|--help)
      print_help
      exit_code=$?
      exit $exit_code
      ;;
    -config_root|---config_root)
      shift
      CONFIG_ROOT="$1"
      ;;
    -project_code|--project_code)
      shift
      PROJECT_CODE="$1"
      ;;
    -replicate_map|--replicate_map)
      shift # past argument
      REPLICATE_MAP="$1"
      ;;
    -assay_type|--assay_type)
      shift # past argument
      ASSAY_TYPE="$1"
      ;;
    --default)
      DEFAULT=YES
      ;;
    *)
      printf "Unknown parameter: %s \n" "$1"
      shift
      ;;
  esac
  shift # past argument or value
done

echo CONFIG_ROOT = "${CONFIG_ROOT}"
echo PROJECT_CODE = "${PROJECT_CODE}"
echo REPLICATE_MAP = "${REPLICATE_MAP}"
echo ASSAY_TYPE = "${ASSAY_TYPE}"

IFS=',' read -r -a plates <<< "${PLATES}"

batch_index=${AWS_BATCH_JOB_ARRAY_INDEX}
PLATE="${plates[${batch_index}]}"
echo "PLATE IS: ${PLATE}"

IFS='_' read -r -a plate_token <<< "${PLATE}";

plate_map=${plate_token[0]}.${plate_token[3]}

if [ "${REPLICATE_MAP}" = "TRUE" ];
then
    PLATE_MAP_PATH="${CONFIG_ROOT}${PROJECT_CODE}/map_src/${plate_token[0]}.${plate_token[3]}.src"
else
    PLATE_MAP_PATH="${CONFIG_ROOT}${PROJECT_CODE}/map_src/${plate_token[0]}.src"
fi

echo PLATE_MAP_PATH = "${PLATE_MAP_PATH}"
OUTFILE="${CONFIG_ROOT}${PROJECT_CODE}/${plate_token[0]}_${plate_token[1]}_${plate_token[2]}"

echo OUTFILE = "${OUTFILE}"
# Activate conda environment

source activate merino

cd /cmap/merino/

python setup.py develop

CSV_FILEPATH="${CONFIG_ROOT}${PROJECT_CODE}/lxb/${PLATE}/${PLATE}.jcsv"
echo CSV_FILEPATH = "${CSV_FILEPATH}"
echo python /cmap/merino/merino/assemble/assemble.py -pmp ${PLATE_MAP_PATH} -csv ${CSV_FILEPATH} -out ${OUTFILE} -assay_type ${ASSAY_TYPE}
python /cmap/merino/merino/assemble/assemble.py -pmp ${PLATE_MAP_PATH} -csv ${CSV_FILEPATH} -out ${OUTFILE} -assay_type ${ASSAY_TYPE}
exit_code=$?

# Deactivate conda environment
source deactivate
exit $exit_code

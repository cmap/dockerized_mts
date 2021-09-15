#!/usr/bin/env bash

while [[ $# > 1 ]]
do

key="$1"

case $key in
    -config_root)
    CONFIG_ROOT="$2"
    shift # past argument
    ;;
    -project_code)
    PROJECT_CODE="$2"
    shift # past argument
    ;;
    -replicate_map)
    REPLICATE_MAP="$2"
    shift # past argument
    ;;
    -assay_type)
    ASSAY_TYPE="$2"
    shift # past argument
    ;;
    --default)
    DEFAULT=YES
    ;;
    *)
            # unknown option
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

if [ "${plate_token[1]}" = "DP78" ];
then
    DP7_PLATE="${plate_token[0]}_DP7_${plate_token[2]}_${plate_token[3]}_${plate_token[4]}"
    DP8_PLATE="${plate_token[0]}_DP8_${plate_token[2]}_${plate_token[3]}_${plate_token[4]}"

    DP7_CSV_PATH="${CONFIG_ROOT}${PROJECT_CODE}/lxb/${DP7_PLATE}/${DP7_PLATE}.csv"
    DP8_CSV_PATH="${CONFIG_ROOT}${PROJECT_CODE}/lxb/${DP8_PLATE}/${DP8_PLATE}.csv"
    DAVEPOOL_ID_CSV_FILEPATH_PAIRS="DP7 ${DP7_CSV_PATH} DP8 ${DP8_CSV_PATH}"
    echo "DAVEPOOL_ID_CSV_FILEPATH_PAIRS ${DAVEPOOL_ID_CSV_FILEPATH_PAIRS}"

    python /cmap/merino/merino/assemble/assemble.py -assay_type "DP78" -pmp ${PLATE_MAP_PATH} -dp_csv ${DAVEPOOL_ID_CSV_FILEPATH_PAIRS} -out ${OUTFILE}
    exit_code=$?
else
    CSV_FILEPATH="${CONFIG_ROOT}${PROJECT_CODE}/lxb/${PLATE}/${PLATE}.jcsv"
    echo CSV_FILEPATH = "${CSV_FILEPATH}"
    python /cmap/merino/merino/assemble/assemble.py -pmp ${PLATE_MAP_PATH} -csv ${CSV_FILEPATH} -out ${OUTFILE} -assay_type ${ASSAY_TYPE}
    exit_code=$?
fi

# Deactivate conda environment
source deactivate
exit $exit_code

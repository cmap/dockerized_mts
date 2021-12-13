#!/usr/bin/env bash


while test $# -gt 0; do
  case "$1" in
    -f| --compound_key_file)
      shift
      COMPOUND_KEY_JSON=$1
      ;;
    -s|--s3_location)
      shift
      S3_LOCATION=$1
      ;;
    -i|--build_id)
      shift
      BUILD_ID=$1
      ;;
    -p|--project_name)
      shift
      PROJECT_NAME=$1
      ;;
    *)
      printf "Unknown parameter: %s \n" "$1"
      shift
      ;;
  esac
  shift
done
NL=$'\n'
errorMessage=""

if [[ ! -z "${S3_LOCATION}" && ! -z "${BUILD_ID}" ]]
then
    if [[ ! -z "${AWS_BATCH_JOB_ARRAY_INDEX}" ]]
    then
        if [[ ! -z "${COMPOUND_KEY_JSON}" ]]
        then
            batch_index=${AWS_BATCH_JOB_ARRAY_INDEX}
            project=$(cat "${COMPOUND_KEY_JSON}" | jq -r --argjson index ${batch_index} '.[$index].x_project_id')
            PROJECT_NAME="${project}"
            INDEX_PAGE="${S3_LOCATION}"/"${PROJECT_NAME,,}"/index.html
        else
            errorMessage="$errorMessage Array jobs must follow the following pattern${NL}"
            errorMessage="$errorMessage register -f <COMPOUND_KEY_JSON> -s <S3_LOCATION> -i <BUILD_ID>${NL}"
        fi
    elif [[ ! -z "${COMPOUND_KEY_JSON}" ]]
    then
        batch_index=0
        project=$(cat "${COMPOUND_KEY_JSON}" | jq -r --argjson index ${batch_index} '.[$index].x_project_id')
        PROJECT_NAME="${project}"
        INDEX_PAGE="${S3_LOCATION}"/"${PROJECT_NAME,,}"/index.html
    elif [[ ! -z "${PROJECT_NAME}" ]]
    then
        INDEX_PAGE="${S3_LOCATION}"/"${PROJECT_NAME,,}"/index.html
    else
        errorMessage="$errorMessage Invoke with the following pattern${NL}"
        errorMessage="$errorMessage register -s <S3_LOCATION> -i <BUILD_ID> -p <PROJECT_NAME>${NL}"
    fi
else
    errorMessage="$errorMessage Invoke with the following pattern${NL}"
    errorMessage="$errorMessage register -s <S3_LOCATION> -i <BUILD_ID> [-p PROJECT_NAME | -f COMPOUND_KEY_JSON]${NL}"
fi

echo  "${PROJECT_NAME}" "${INDEX_PAGE}"  "${BUILD_ID}"

if [[ -z "${errorMessage}" ]]
then
    node ./index.js "${PROJECT_NAME}" "${INDEX_PAGE}"  "${BUILD_ID}"
else
    echo "${errorMessage}"
    exit -1
fi

exit_code=$?
exit ${exit_code}

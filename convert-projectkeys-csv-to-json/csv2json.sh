#!/bin/bash


while test $# -gt 0; do
  case "$1" in
    -f| --compound_key_file)
      shift
      COMPOUND_KEY=$1
      ;;
    -o|--out)
      shift
      COMPOUND_KEY_JSON=$1
      ;;
    *)
      printf "Unknown parameter: %s \n" "$1"
      shift
      ;;
  esac
  shift
done


if [[ ! -z $COMPOUND_KEY && ! -z $COMPOUND_KEY_JSON  ]]
then
  npx csvtojson $COMPOUND_KEY > $COMPOUND_KEY_JSON
  node ./index.js $COMPOUND_KEY_JSON

else
  echo "The full path to both compound key file and output json file must be specified"
  exit 1
fi

exit_code=$?
exit $exit_code

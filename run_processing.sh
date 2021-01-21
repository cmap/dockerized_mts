#!/bin/bash

while IFS=, read -r project name id dose ndose fold proj; do
  echo "$name $project"
  if [ "$name" == "pert_name" ] || [ "$name" == "DMSO" ] || [ "$name" == "CMAP-000" ] ; then
     continue
  fi
  arg_string='[ { "project_id": "'$project'", "pert_name": "'$name'" } ]'
  echo $arg_string

  docker run \
  -v /Users/aboghoss/Downloads/MTS015_PR500_reprocess:/data \
  -e projects="$arg_string" \
  -e AWS_BATCH_JOB_ARRAY_INDEX=0 \
  cmap/clue-mts \
  -i /data \
  -o /data \
  -t "1" \
  -a "PR500"

done < /Users/aboghoss/Downloads/MTS015_PR500_reprocess/project_key.csv

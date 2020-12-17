#!/bin/bash

while IFS=, read -r name project; do
  echo "$name $project"
  if [ "$name" == "pert_name" ] || [ "$name" == "DMSO" ] || [ "$name" == "CMAP-000" ] ; then
     continue
  fi
  docker run \
  -v /Users/aboghoss/Downloads/MTS015_PR500:/data \
  -e projects="[ { 'project_id': $project, 'pert_name': $name } ]" \
  -e AWS_BATCH_JOB_ARRAY_INDEX=0 \
  cmap/clue-mts \
  -i /data \
  -o /data \
  -t "1"

done < ~/Downloads/MTS015_PR500/project_key.csv

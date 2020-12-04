#!/bin/bash

while IFS=, read -r name project; do
  echo "$name $project"
  if [ "$name" == "pert_name" ] || [ "$name" == "DMSO" ] || [ "$name" == "CMAP-000" ] ; then
     continue
  fi
  docker run \
  -v /Users/aboghoss/Downloads/DEEP_pruned:/data \
  -e projects="[ { 'project_id': $project, 'pert_name': $name } ]" \
  -e AWS_BATCH_JOB_ARRAY_INDEX=0 \
  cmap/clue-mts \
  -i /data \
  -o /data \
  -t "1"

done < ~/Downloads/DEEP_pruned/project_key.csv

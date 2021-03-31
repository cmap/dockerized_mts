#!/bin/bash

while IFS=, read -r project id name; do
  echo "$name $project"

  # skip header
  if [ "$name" == "pert_name" ] || [ "$name" == "DMSO" ] || [ "$name" == "CMAP-000" ] ; then
     continue
  fi
  arg_string='[ { "project_id": "'$project'", "pert_name": "'$name'" } ]'
  echo $arg_string

  # submit to docker
  docker run --rm \
  -v /Users/aboghoss/Downloads/PREP_300:/data \
  -e projects="$arg_string" \
  -e AWS_BATCH_JOB_ARRAY_INDEX=0 \
  cmap/clue-mts \
  -i /data \
  -o /data \
  -t "1" \
  -a "PR300" &

  # keep number of jobs under number of processors
  [ $( jobs | wc -l ) -ge 4 ] && wait

done < /Users/aboghoss/Downloads/PREP_300_reprocess/project_key.csv
wait

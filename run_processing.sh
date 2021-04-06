#!/bin/bash

while IFS=, read -r project name id; do
  echo "$name $project"

  # skip header
  if [ "$name" == "pert_name" ] || [ "$name" == "DMSO" ] || [ "$name" == "CMAP-000" ] ; then
     continue
  fi
  arg_string='[ { "project_id": "'$project'", "pert_name": "'$name'" } ]'
  echo $arg_string

  # submit to docker
  docker run --rm \
  -v /Users/aboghoss/Downloads/MTS016_PR500:/data \
  -e projects="$arg_string" \
  -e AWS_BATCH_JOB_ARRAY_INDEX=0 \
  aboghoss/clue-mts:dev \
  -i /data \
  -o /data \
  -t "1" \
  -a "PR300" &

  # keep number of jobs under number of processors
  [ $( jobs | wc -l ) -ge 4 ] && wait

done < /Users/aboghoss/Downloads/MTS016_PR500/project_key.csv
wait

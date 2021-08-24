#!/bin/bash
data_dir=$1
out_dir=$2
key_tab=$3

while IFS=, read -r project id name plate mult; do
  echo "$name $plate $project"

  # skip header
  if [ "$name" == "pert_name" ] || [ "$name" == "DMSO" ] || [ "$name" == "CMAP-000" ] ; then
     continue
  fi
  arg_string='[ { "project_id": "'$project'", "pert_name": "'$name'", "compound_plate": "'$plate'", "multiple_plates": "'$mult'" } ]'
  echo $arg_string

  # submit to docker
  docker run --rm \
    -v "$data_dir":/data \
    -v "$out_dir":/out_dir \
    -e projects="$arg_string" \
    -e AWS_BATCH_JOB_ARRAY_INDEX=0 \
    cmap/drc-module:dev \
    -i /data \
    -o /out_dir \
    -g "0" &

  # keep number of jobs under number of processors
  [ $( jobs | wc -l ) -ge 4 ] && wait

done < "$key_tab"
wait

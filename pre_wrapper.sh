#!/bin/bash

# read in flagged arguments
while getopts ":i:o:a:p:" arg; do
  case $arg in
    i) # specify input folder
      data_dir=${OPTARG};;
    o) # specifcy output folder
      output_dir=${OPTARG};;
    a) # specify assay/build (PR300 or PR500)
      assay=${OPTARG};;
    p) # specify project key directory
      project_key=${OPTARG};;
  esac
done

# run docker container with arguments
docker run -it \
  -v $data_dir:/data \
  -v $output_dir:/results \
  cmap/clue-mts-int:latest "data" "results" "$assay" "$project_key"

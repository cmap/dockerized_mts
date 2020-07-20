#!/bin/bash

# read in flagged arguments
while getopts ":i:o:p:a:" arg; do
  case $arg in
    i) # specify input folder
      data_dir=${OPTARG}
      ;;
    o) # specifcy output folder
      output_dir=${OPTARG}
      ;;
    p) # specify project name
      project=${OPTARG}
      ;;
    a) # specify assay/build (PR300 or PR500)
      assay=${OPTARG}
  esac
done

# run docker container with arguments
docker run -it \
  -v $data_dir:/data \
  -v $output_dir:/results \
  cmap/clue-mts:v0.0.1 "data" "results" "$project" "$assay"

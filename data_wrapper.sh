#!/bin/bash

# read in flagged arguments
while getopts ":i:p:" arg; do
  case $arg in
    i) # specify input folder
      data_dir=${OPTARG};;
    o) # specifcy output folder
      output_dir=${OPTARG};;
    a) # specify project name
      project=${OPTARG};;
    p) # specify pert_name (compound)
      comp=${OPTARG};;
  esac
done

# run docker container with arguments
docker run -it \
  -v $data_dir:/data \
  -v $output_dir:/results \
  cmap/clue-mts:latest "data" "results" "$project" "$comp"

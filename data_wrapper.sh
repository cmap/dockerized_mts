#!/bin/bash

# read in flagged arguments
while getopts ":i:p:" arg; do
  case $arg in
    i) # specify input folder
      data_dir=${OPTARG};;
    p) # specify project name
      project=${OPTARG};;
  esac
done

# run docker container with arguments
docker run -it \
  -v $data_dir:/data \
  cmap/clue-mts-int:latest "data" "$project"

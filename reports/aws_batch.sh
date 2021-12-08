#!/usr/bin/env bash

# read in flagged arguments
while getopts ":d:c:m:" arg; do
  case $arg in
    d) # specify input folder (plate level)
      data_dir=${OPTARG};;
    c) # compound name (ID or file name same string)
      compound=${OPTARG};;
    m) # path to metadata about lineage and mutations
      meta_path=${OPTARG}
  esac
done

export HDF5_USE_FILE_LOCKING=FALSE

echo "${data_dir}" "${compound}" "${meta_path}"

Rscript -e \
  "suppressMessages(rmarkdown::render('rmarkdown/compound_report.Rmd', \
  output_file = paste0('$compound', '_report.html'), output_dir = '$data_dir', \
  params = list(data_dir='$data_dir', comp='$compound', meta_folder='$meta_path'), \
  quiet = TRUE))"

Rscript -e \
  "suppressMessages(rmarkdown::render('rmarkdown/drc_report.Rmd', \
  output_file = paste0('$compound', '_drc.html'), output_dir = '$data_dir', \
  params = list(data_dir='$data_dir', comp='$compound'), \
  quiet = TRUE))"

exit_code=$?

echo "$exit_code"
exit $exit_code

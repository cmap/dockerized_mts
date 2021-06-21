# Install script for QC module Dockerfile
options(repos=structure(c(CRAN="http://cran.r-project.org")))

install.packages("tidyverse")
install.packages("magrittr")
install.packages("data.table")
install.packages("readr")
install.packages("scam")
install.packages("stats")
install.packages("hdf5r")
install.packages("reshape2")

# set up BiocManager
install.packages("BiocManager")
BiocManager::install()
BiocManager::install("sva")
install.packages("PRROC")

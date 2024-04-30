# Helper functions for the initial processing step of the MTS pipeline

#---- Load Packages ----
library(tidyverse)
library(magrittr)
library(data.table)
library(sva)
library(readr)
library(stats)
library(reshape2)
library(argparse)

#---- LFC calculation ----
calculate_lfc <- function(df) {
  res <- df %>%
    dplyr::group_by(prism_replicate, ccle_name, culture, pert_time, pert_vehicle, barcode_id) %>%
    dplyr::mutate(med_ctl_vehicle = median(logMFI_norm[pert_type == "ctl_vehicle" & pert_iname == pert_vehicle]),
                  LFC = logMFI_norm - med_ctl_vehicle) %>%
    dplyr::ungroup() %>%
    dplyr::select(-logMFI, -logMFI_norm, -med_ctl_vehicle)
  
  return(res)
}

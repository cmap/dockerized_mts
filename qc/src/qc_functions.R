# Helper functions for the initial processing step of the MTS pipeline

#---- Load Packages ----
library(tidyverse)
library(magrittr)
library(data.table)
library(readr)
library(stats)
library(reshape2)
library(sva)
library(PRROC)
library(argparse)

#---- QC calculations ----
# calculate SSMD and NNMD
calc_ssmd <- function(df) {
  SSMD_table <- df %>%
    # look at controls
    dplyr::filter(pert_type %in% c("ctl_vehicle", "trt_poscon")) %>%
    dplyr::distinct(ccle_name, rid, pert_type, prism_replicate, logMFI_norm, profile_id,
                    pert_time, pool_id, culture, pert_plate, pert_vehicle) %>%
    # group common controls
    dplyr::group_by(pert_type, prism_replicate, pert_time, ccle_name, rid,
                    pool_id, culture, pert_plate, pert_vehicle) %>%
    # take median and mad of results
    dplyr::summarise(med = median(logMFI_norm, na.rm = TRUE),
                     mad = mad(logMFI_norm, na.rm = TRUE), .groups = "drop") %>%
    # add to table
    dplyr::mutate(pert_type_md = paste0(pert_type, '_md'),
                  pert_type_mad = paste0(pert_type, '_mad')) %>%
    # spread to columns
    tidyr::spread(key = pert_type_md, value = med, fill = 0) %>%
    tidyr::spread(key = pert_type_mad, value = mad, fill = 0) %>%
    dplyr::ungroup() %>%
    dplyr::select(-pert_type) %>%
    # give each control all values (median and mad for vehicle and poscon)
    dplyr::group_by(prism_replicate, ccle_name, pert_time, rid, pool_id, culture, pert_plate, pert_vehicle) %>%
    dplyr::summarise_all(sum) %>%
    # calculate SSMD and NNMD
    dplyr::mutate(ssmd = tryCatch(expr = {
      (ctl_vehicle_md - trt_poscon_md) / sqrt(ctl_vehicle_mad^2 +trt_poscon_mad^2)},
      error = function(e) {
        return(NA)
      }),
      nnmd = tryCatch(expr = {
        (ctl_vehicle_md - trt_poscon_md) / ctl_vehicle_mad},
        error = function(e) {
          return(NA)
        })
    )
  
  return(SSMD_table)
}

# calculate error rates
calc_er <- function(df) {
  er_table <- df %>%
    dplyr::filter(pert_type %in% c("ctl_vehicle", "trt_poscon"),
                  is.finite(logMFI_norm),
                  pool_id != "CTLBC") %>%
    dplyr::group_by(rid, ccle_name, culture, prism_replicate, pert_plate, pert_vehicle) %>%
    dplyr::summarise(error_rate =
                       min(PRROC::roc.curve(scores.class0 = logMFI_norm,
                                            weights.class0 = pert_type == "ctl_vehicle",
                                            curve = TRUE)$curve[,1] + 1 -
                             PRROC::roc.curve(scores.class0 = logMFI_norm,
                                              weights.class0 = pert_type == "ctl_vehicle",
                                              curve = TRUE )$curve[,2])/2,
                     .groups = "drop")
  
  return(er_table)
}

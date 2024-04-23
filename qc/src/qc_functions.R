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
                    pert_time, pool_id, culture, pert_plate, pert_vehicle, barcode_id) %>%
    # group common controls
    dplyr::group_by(pert_type, prism_replicate, pert_time, ccle_name, rid,
                    pool_id, culture, pert_plate, pert_vehicle, barcode_id) %>%
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
    dplyr::group_by(prism_replicate, ccle_name, pert_time, rid, pool_id, culture, pert_plate, pert_vehicle, barcode_id) %>%
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
    dplyr::group_by(rid, ccle_name, culture, prism_replicate, pert_plate, pert_vehicle, barcode_id) %>%
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

#' Calculate floor_range metric and annotate Pass/Fail status
#'
#' This function calculates the floor_range metric for cell lines based on the median
#' logMFI values of a specific analyte in control vehicle and compares it to each cell line
#' in control vehicle on a per detection plate bases. It merges the calculated metrics,
#' evaluates against a threshold, and determines if each cell line passes or fails 
#' based on the floor_range metric.
#'
#' @param df A data frame containing the necessary data, including columns for 
#'   `prism_replicate`, `ccle_name`, `pert_type`, `logMFI`, `barcode_id` and other identifiers.
#' @param threshold A numeric value setting the minimum acceptable floor_range value 
#'   for a cell line to pass. Defaults to -log2(0.3) indicating 30% viability.
#'
#' @return A data frame with columns `prism_replicate`, `ccle_name`, `barcode_id`,
#'   `floor_range_vehicle_md`, and `pass_fr`. This includes the median floor range
#'   vehicle metric per cell line and plate, along with a logical indicator if the 
#'   cell line passed the threshold.
make_fr_table <- function(df, threshold = -log2(0.3)) {
  # Calculate analyte 6 median in vehicle for each plate
  # TODO Change ccle_name to list parameter
  floor_median_vehicle <- df %>%
    dplyr::filter(ccle_name == 'prism invariant 6', pert_type == 'ctl_vehicle') %>%
    dplyr::group_by(prism_replicate) %>%
    dplyr::summarise(logMFI_floor = median(logMFI, na.rm = TRUE), .groups = 'drop')  # Calculate median and drop groups, removing NA values
  
  # Calculate median of each cell line in DMSO, ignoring NA values
  cell_median <- df %>%
    dplyr::filter(pool_id != 'CTLBC', pert_type == 'ctl_vehicle') %>%
    dplyr::group_by(prism_replicate, ccle_name, barcode_id, pert_well) %>%
    dplyr::summarise(logMFI = median(logMFI, na.rm = TRUE), .groups = 'drop')  # Calculate median and drop groups, removing NA values
  
  # Merge into cell median
  fr_table <- dplyr::left_join(cell_median, floor_median_vehicle, by = "prism_replicate")
  
  # Calculate floor_range
  fr_table <- fr_table %>%
    # Calculate floor_range_vehicle
    dplyr::mutate(floor_range_vehicle = logMFI - logMFI_floor) %>%
    # Group by necessary identifiers
    dplyr::group_by(prism_replicate, ccle_name, barcode_id) %>%
    # Calculate the median of floor_range_vehicle for each cell line/plate
    dplyr::summarise(floor_range_vehicle_md = median(floor_range_vehicle, na.rm = TRUE), .groups = 'drop')
  
  # Add pass/fair flag for both metrics
  fr_table <- fr_table %>%
    dplyr::mutate(pass_fr = !is.na(floor_range_vehicle_md) & floor_range_vehicle_md >= threshold) %>%
    # Select relevant columns
    dplyr::select(prism_replicate, ccle_name, barcode_id, floor_range_vehicle_md, pass_fr)
  
  
  # Return the final table
  return(fr_table)
}

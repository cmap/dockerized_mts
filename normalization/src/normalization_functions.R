# Helper functions for the initial processing step of the MTS pipeline

#---- Load Packages ----
library(tidyverse)
library(magrittr)
library(data.table)
library(argparse)
library(readr)
library(scam)
library(stats)
library(hdf5r)
library(reshape2)
library(splitstackshape)

#---- Reading ----
# HDF5 file reader
read_hdf5 <- function(filename, index = NULL) {
  fun_call <- match.call()
  hdf5_obj <- hdf5r::H5File$new(filename, mode = "r+")
  hdf5_attributes <- hdf5r::h5attributes(hdf5_obj)
  matrix_dims <- hdf5_obj[["0/DATA/0/matrix"]][["dims"]]
  if (is.null(index)) {
    index <- list(1:matrix_dims[1], 1:matrix_dims[2])
  }
  data_matrix <- hdf5_obj[["0/DATA/0/matrix"]][index[[1]],
                                               index[[2]]]
  if (is.null(dim(data_matrix))) {
    data_matrix %<>% matrix(nrow = length(index[[1]]),
                            ncol = length(index[[2]]))
  }
  data_matrix %<>%
    magrittr::set_rownames(hdf5_obj[["0/META/ROW/id"]][index[[1]]] %>%
                             gsub(" *$", "", .)) %>%
    magrittr::set_colnames(hdf5_obj[["0/META/COL/id"]][index[[2]]] %>%
                             gsub(" *$", "", .))
  hdf5_obj$close_all()
  return(data_matrix)
}


#---- Compound tracking ----

# make new project_key.csv tracking what to make dose response curves for
write_key <- function(df, out_dir, build_name) {
  df %>%
    dplyr::filter(!pert_type %in% c("trt_poscon", "ctl_vehicle")) %>%
    dplyr::select(pert_iname, pert_id, pert_plate, pert_dose, any_of("x_project_id")) %>%
    dplyr::distinct() %>%
    splitstackshape::cSplit(splitCols = "pert_dose",
                            sep = "|", fixed = T,
                            direction = "wide", drop = T) %>%
    dplyr::group_by(across(-c(colnames(.)[str_detect(colnames(.), pattern = "pert_dose")]))) %>%
    summarise_all(function(x) n_distinct(x, na.rm = T)) %>%
    dplyr::ungroup() %>%
    readr::write_csv(., paste0(out_dir, "/", build_name, "_compound_key.csv"))
}


#---- Normalization ----
# calculate control barcode medians
control_medians <- function(df) {
  ref <- df %>%
    dplyr::filter(pert_type == "ctl_vehicle") %>%  # look at controls
    dplyr::group_by(prism_replicate, pert_well) %>%
    dplyr::mutate(mLMFI = median(logMFI)) %>%  # median of each well on replicate
    dplyr::group_by(prism_replicate, rid) %>%  # median well on each replicate
    dplyr::mutate(mmLMFI = logMFI - mLMFI + median(mLMFI)) %>%  # normalized value for rep (to median well)
    dplyr::summarise(rLMFI = median(mmLMFI), .groups = "drop") %>%  # median normalized value across reps
    dplyr::left_join(df)

  return(ref)
}

# fit scam to control barcode profiles and normalize other data
normalize <- function(df, barcodes, threshold) {
  normalized <- df %>%
    dplyr::group_by(prism_replicate, pert_well) %>%
    dplyr::mutate(n = n()) %>%
    dplyr::filter(n >= threshold) %>%
    dplyr::select(-n) %>%
    # try with k=4 and 5 (to avoid hanging), try again with linear model
    dplyr::mutate(logMFI_norm = tryCatch(
      expr = {tryCatch(
        expr = {scam(y ~ s(x, bs = "micv", k = 4),
                     data = tibble(
                       y = rLMFI[rid %in% barcodes$rid],
                       x = logMFI[rid %in% barcodes$rid])) %>%
            predict(newdata = tibble(x = logMFI)) %>% as.numeric()},
        error = function(e) {
          scam(y ~ s(x, bs = "micv", k = 5),
               data = tibble(
                 y = rLMFI[rid %in% barcodes$rid],
                 x = logMFI[rid %in% barcodes$rid])) %>%
            predict(newdata = tibble(x = logMFI) %>% as.numeric())
        })},
      error = function(e) {
        lm(y ~ x,
           data = tibble(
             y = rLMFI[rid %in% barcodes$rid],
             x = logMFI[rid %in% barcodes$rid])) %>%
          predict(newdata = tibble(x = logMFI)) %>% as.numeric()
      })) %>%
    dplyr::ungroup() %>%
    dplyr::select(-logMFI)

  return(normalized)
}

# fit scam to control barcode profiles and normalize other data
normalize_base <- function(df, barcodes, threshold) {
  normalized <- df %>%
    dplyr::group_by(prism_replicate, pert_well) %>%
    dplyr::mutate(n = n()) %>%
    dplyr::filter(n >= threshold) %>%
    dplyr::select(-n) %>%
    # try with k=4 and 5 (to avoid hanging), try again with linear model
    dplyr::mutate(logMFI_norm = tryCatch(
      expr = {scam(y ~ s(x, bs = "micv"),
                     data = tibble(
                       y = rLMFI[rid %in% barcodes$rid],
                       x = logMFI[rid %in% barcodes$rid])) %>%
            predict(newdata = tibble(x = logMFI)) %>% as.numeric()},
        error = function(e) {
          lm(y ~ x,
             data = tibble(
               y = rLMFI[rid %in% barcodes$rid],
               x = logMFI[rid %in% barcodes$rid])) %>%
            predict(newdata = tibble(x = logMFI)) %>% as.numeric()}
      )) %>%
    dplyr::ungroup() %>%
    dplyr::select(-logMFI)

  return(normalized)
}

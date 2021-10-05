# Helper functions for the initial processing step of the MTS pipeline

#---- Load Packages ----
library(tidyverse)
library(magrittr)
library(data.table)
library(readr)
library(scam)
library(stats)
library(hdf5r)
library(reshape2)

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


#---- Reformatting ----
# function to rename columns (get rid of 2, for make_long_map)
rename_col <- function(cols) {
  if (str_detect(cols, "2")) {
    return(paste(word(cols, 1, sep = "_"), word(cols, 3, -1, sep = "_"),  sep = "_"))
  } else {
    return(cols)
  }
}

# convert a wide platemap to log form
make_long_map <- function(df) {
  pert1 <- df %>%
    dplyr::select(!contains("2"))
  pert2 <- df %>%
    dplyr::select(contains("2"), pert_well, pert_time,
                  prism_replicate, is_well_failure, profile_id, x_project_id)

  colnames(pert2) <- sapply(colnames(pert2), FUN = function(x) rename_col(x))

  if (ncol(pert2) > 6) {
    new_map <- dplyr::bind_rows(pert1, pert2)
  } else {
    pert1  %<>%
      dplyr::filter(pert_iname != "Untrt") %>%
      dplyr::mutate(pert_type = ifelse(pert_iname %in% c("PBS", "DMSO"), "ctl_vehicle", pert_type)) %>%
      dplyr::rename(pert_name = pert_iname, project_id = x_project_id)

    if (!("pert_mfc_id") %in% colnames(pert1)){
      pert1 %<>% dplyr::mutate(pert_mfc_id = pert_id)
    }

    return(pert1)
  }

  new_map %<>%
    dplyr::filter(!(pert_iname %in% c("Untrt", ""))) %>%
    dplyr::select(intersect(colnames(.), colnames(pert2))) %>%
    dplyr::mutate(pert_type = ifelse(pert_iname %in% c("PBS", "DMSO"), "ctl_vehicle", pert_type))

  if (!("pert_mfc_id") %in% colnames(new_map)){
    new_map %<>% dplyr::mutate(pert_mfc_id = pert_id)
  }

  overview <- new_map %>%
    dplyr::group_by(pert_well, prism_replicate, profile_id, x_project_id) %>%
    dplyr::summarise(pert_types = paste(unique(pert_type), collapse = fixed("+")),
                     pert_names = paste(unique(pert_iname), collapse = fixed("+")),
                     n = n(), .groups = "drop") %>%
    dplyr::ungroup() %>%
    dplyr::right_join(new_map, by = c("pert_well", "prism_replicate", "profile_id", "x_project_id")) %>%
    dplyr::filter(!(pert_type == "ctl_vehicle" & str_detect(pert_types, "trt")))  %>%
    dplyr::mutate(pert_iname = ifelse(pert_types == "ctl_vehicle", pert_names, pert_iname),
                  pert_vehicle = ifelse(pert_types == "ctl_vehicle", pert_names, pert_vehicle),
                  pert_id = ifelse(pert_types == "ctl_vehicle", pert_names, pert_id),
                  pert_mfc_id = ifelse(pert_types == "ctl_vehicle", pert_names, pert_mfc_id)) %>%
    dplyr::select(-pert_types, -pert_names, -n) %>%
    dplyr::distinct() %>%
    dplyr::rename(pert_name = pert_iname, project_id = x_project_id)

  return(overview)
}

# make project_key.csv
write_key <- function(df, out_dir) {
  df %>%
    dplyr::filter(project_id != "controls") %>%
    dplyr::distinct(pert_name, pert_mfc_id, project_id, prism_replicate) %>%
    dplyr::mutate(compound_plate = stringr::word(prism_replicate, 1, sep = fixed("_"))) %>%
    dplyr::distinct(pert_name, pert_mfc_id, project_id, compound_plate) %>%
    dplyr::group_by(pert_name, pert_mfc_id, project_id) %>%
    dplyr::mutate(n_plates = n()) %>%
    dplyr::ungroup() %>%
    dplyr::distinct() %>%
    readr::write_csv(., paste0(out_dir, "/project_key.csv"))
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
normalize <- function(df, barcodes) {
  normalized <- df %>%
    dplyr::group_by(prism_replicate, pert_well) %>%
    # try with k=4 and 5 (to avoid hanging), try again with linear model
    dplyr::mutate(LMFI = tryCatch(
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
          predict(newdata = tibble(x = logMFI) %>% as.numeric())
      })) %>%
    dplyr::ungroup() %>%
    dplyr::select(-logMFI)

  return(normalized)
}

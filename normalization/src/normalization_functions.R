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
library(R.utils)
library(httr)
library(jsonlite)

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

#---- Extract BASE plate ----

extract_baseplate <- function(instinfo, base_string="BASE",inst_column = "prism_replicate" ){
  
  base_plate_inst = instinfo %>%
  dplyr::filter(str_detect(.data[[inst_column]], base_string))
  
  return(base_plate_inst)
}


build_master_logMFI <- function(raw_matrix, inst_info, cell_info, count_table,
                                data_col = "logMFI"){
  
  master_logMFI = log2(raw_matrix + 1) %>%
    reshape2::melt(varnames = c("rid", "profile_id"), value.name = data_col) %>%
    dplyr::filter(is.finite(logMFI)) %>%
    dplyr::inner_join(cell_info) %>%
    dplyr::inner_join(inst_info) %>%
    dplyr::inner_join(count_table) %>%
    dplyr::mutate(instance_id = paste(profile_id, ccle_name, sep=":"))
  
  return(master_logMFI)
}

build_count_table <- function(count_matrix, data_col = "count"){
  master_count = count_matrix %>%
    reshape2::melt(varnames = c("rid", "profile_id"), value.name = data_col)

  return(master_count)
}

#---- Compound tracking ----

# make new project_key.csv tracking what to make dose response curves for
write_key <- function(df, out_dir, build_name) {
  df %>%
    dplyr::filter(!pert_type %in% c("trt_poscon", "ctl_vehicle")) %>%
    dplyr::select(pert_iname, pert_id, pert_plate, pert_dose, pert_vehicle, any_of("x_project_id")) %>%
    dplyr::distinct() %>%
    splitstackshape::cSplit(splitCols = "pert_dose",
                            sep = "|", fixed = T,
                            direction = "wide", drop = T,
                            type.convert = F) %>%
    dplyr::group_by(across(-c(colnames(.)[str_detect(colnames(.), pattern = "pert_dose")]))) %>%
    summarise_all(function(x) n_distinct(x, na.rm = T)) %>%
    dplyr::ungroup() %>%
    write.csv(., paste0(out_dir, "/", build_name, "_compound_key.csv"), row.names=FALSE)
}


#---- Normalization ----
# calculate control barcode medians
control_medians <- function(df) {
  ref <- df %>%
    dplyr::filter(pert_type == "ctl_vehicle") %>%  # look at controls
    dplyr::group_by(prism_replicate, pert_well, pert_vehicle) %>%
    dplyr::mutate(mLMFI = median(logMFI)) %>%  # median of each well on replicate
    dplyr::group_by(prism_replicate, pert_vehicle, rid) %>%  # median well on each replicate
    dplyr::mutate(mmLMFI = logMFI - mLMFI + median(mLMFI)) %>%  # normalized value for rep (to median well)
    dplyr::summarise(rLMFI = median(mmLMFI), .groups = "drop") %>%  # median normalized value across reps
    dplyr::left_join(df)
  
  return(ref)
}

# fit scam to control barcode profiles and normalize other data
normalize <- function(df, barcodes, threshold) {
  normalized <- df %>%
    dplyr::group_by(prism_replicate, pert_well, pert_vehicle) %>%
    dplyr::mutate(n = n()) %>%
    dplyr::filter(n >= threshold) %>%
    dplyr::select(-n) %>%
    dplyr::mutate(logMFI_norm = tryCatch(
      expr = {tryCatch(
        expr = {
          R.utils::withTimeout(
            expr = {
              scam(y ~ s(x, bs = "micv", k = 4),
                   data = tibble(
                     y = rLMFI[rid %in% barcodes$rid],
                     x = logMFI[rid %in% barcodes$rid])) %>%
                predict(newdata = tibble(x = logMFI)) %>% as.numeric()
            }, timeout = 2, onTimeout = "error"
          )
        }, error = function(e) {
          R.utils::withTimeout(
            expr = {
              scam(y ~ s(x, bs = "micv", k = 5),
                   data = tibble(
                     y = rLMFI[rid %in% barcodes$rid],
                     x = logMFI[rid %in% barcodes$rid])) %>%
                predict(newdata = tibble(x = logMFI) %>% as.numeric())
            }, timeout = 2, onTimeout = "error"
          )
        })}, error = function(e) {
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
    dplyr::group_by(prism_replicate, pert_well, pert_vehicle) %>%
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

make_request_url_filter <- function(endpoint_url, where=NULL) {
  full_url <- paste0(endpoint_url, "/api/data/")
  if (!is.null(where)) {
    # Manually construct the filter string
    filter_str <- sprintf('{"where":{"%s":"%s"}}', names(where), where[[1]])
    
    # Manually replace characters to match exact URL encoding
    filter_encoded <- gsub("\\{", "%7B", filter_str)
    filter_encoded <- gsub("\\}", "%7D", filter_encoded)
    filter_encoded <- gsub(":", "%3A", filter_encoded)
    filter_encoded <- gsub("\"", "%22", filter_encoded)
    
    # Construct the full URL
    request_url <- sprintf('%s?filter=%s', gsub("/$", "", full_url), filter_encoded)
    return(request_url)
  } else {
    return(full_url)
  }
}


get_data_from_db <- function(endpoint_url, user_key, where=NULL) {
  # Construct the request URL using the make_request_url_filter function
  request_url <- make_request_url_filter(endpoint_url, where)
  cat("Request URL:", request_url, "\n")  # Print the request URL for verification
  
  # Make the HTTP GET request using the httr package
  response <- GET(url = request_url, add_headers(user_key = user_key))
  
  # Check if the request was successful
  if (response$status_code == 200) {
    # Parse and return the JSON content from the response
    return(fromJSON(content(response, "text")))
  } else {
    # Handle errors
    cat("Error in the request: ", response$status_code, "\n")
    cat("Response content: ", content(response, "text"), "\n")
    stop("Request failed")
  }
}


filter_lowcounts <- function(df, min_count = 10, threshold = 0.25) {
  cat("Finding instances with count < min_count...\n")
  low_count_instances <- df %>%
    filter(count < min_count) %>%
    pull(instance_id)
  
  cat("Calculating fraction of instances to remove per combination...\n")
  fraction_to_remove <- df %>%
    group_by(prism_replicate, pert_well) %>%
    summarise(n_low_count = sum(count < min_count), .groups = 'drop') %>%
    mutate(n_total = n(), fraction_to_remove = n_low_count / n_total)
  
  cat("Identifying combinations exceeding removal threshold...\n")
  combinations_to_remove <- fraction_to_remove %>%
    filter(fraction_to_remove >= threshold) %>%
    select(prism_replicate, pert_well)
  
  cat("Filtering instances and combinations...\n")
  # First, filter out low count instances
  filtered_df <- df %>%
    filter(!(instance_id %in% low_count_instances))
  
  # Then, perform an anti_join to remove combinations exceeding the threshold
  filtered_df <- anti_join(filtered_df, combinations_to_remove, by = c("prism_replicate", "pert_well"))
  
  return(list(filtered_df = filtered_df,
              removed_instances = low_count_instances,
              removed_wells = combinations_to_remove))
}

#---- Remove poorly performing pool/pert/dose instances ----

calculate_deltas <- function(df) {
  # Filter and calculate median values for each treatment on each plate
  median_df <- df %>%
    dplyr::filter(pool_id != "CTLBC") %>%
    dplyr::group_by(rid, ccle_name, culture, pert_plate, pert_type, pert_iname, pert_dose) %>%
    dplyr::summarise(
      LMFI_median = median(logMFI, na.rm = TRUE),
      LMFI_norm_median = median(logMFI_norm, na.rm = TRUE),
      .groups = 'drop'  # Automatically ungroup after summarisation
    )
  
  # Merge the original dataframe with the medians and calculate deltas
  delta_df <- dplyr::left_join(df, median_df, by = c("rid", "ccle_name", "culture",
                                                     "pert_type", "pert_iname", "pert_dose",
                                                     "pert_plate")) %>%
    dplyr::mutate(
      delta_LMFI = logMFI - LMFI_median,
      delta_LMFI_norm = logMFI_norm - LMFI_norm_median
    )

  return(delta_df)
}


calculate_replicate_correlations <- function(df) {
  # Calculate correlation between replicates
  replicate_correlations <- df %>%
    dplyr::filter(pool_id != "CTLBC") %>%
    dplyr::group_by(pool_id, pert_well, pert_iname, pert_dose, pert_type, pert_id) %>%
    dplyr::summarise(LMFI_norm_corr = cor(LMFI_norm_median, logMFI_norm), na.rm = TRUE) %>%
    dplyr::ungroup() %>%
    dplyr::right_join(df, by = c("pert_id","pert_well","pert_iname","pert_dose",
                                 "pert_type","pool_id"))
  
  return(replicate_correlations)
}


annotate_rep_corr_pass <- function(df, corr_threshold = 0.6, delta_threshold = 3) {
  # Annotate the dataframe with pass/fail based on the correlation and delta logMFI values
  # If both correlations are not met, the pool+well fails, otherwise, it passes.
  df <- df %>%
    mutate(pass_rc = !((LMFI_norm_corr < corr_threshold) & 
                      (abs(delta_LMFI_norm_median) > delta_threshold)))
  
  return(df)
}


# Script to run the QC step of the MTS pipeline
# creates SSMD_TABLE

# import necessary libraries and functions using MTS_functions.R
suppressMessages(source("./src/MTS_functions.R"))

#---- Read arguments ----
script_args <- commandArgs(trailingOnly = TRUE)
if (length(script_args) != 2) {
  stop("Please supply path to data and output directory",
       call. = FALSE)
}
base_dir <- script_args[1]  # input directory
out_dir <- script_args[2]  # output directory

if (!dir.exists(out_dir)) {dir.create(out_dir, recursive = T)}

# paths to data (make sure directory of data has these files)
path_data <- paste0(base_dir, "/logMFI_NORMALIZED.csv")

#---- Load the data ----

# read in normalized logMFI data
logMFI_normalized <- data.table::fread(path_data)

#---- Calculate QC metrics ----

# calculate SSMD and NNMD (allow for no QC)
SSMD_TABLE <- calc_ssmd(logMFI_normalized %>% dplyr::filter(pool_id != "CTLBC"))
if (any(is.na(SSMD_TABLE$ssmd))) {
  message("Unable to calculate some QC metrics: control condition(s) may be missing")
}

# if there are positive controls
if ("trt_poscon_md" %in% colnames(SSMD_TABLE)) {
  
  # calculate error rate of normalized table (based on threshold classifier)
  error_table <- calc_er(logMFI_normalized)
  
  # join with SSMD table
  SSMD_TABLE %<>%
    dplyr::left_join(error_table) %>%
    dplyr::mutate(compound_plate = stringr::word(prism_replicate, 1,
                                                 sep = stringr::fixed("_")),
                  dr = ctl_vehicle_md - trt_poscon_md,
                  pass = error_rate <= 0.05 & dr > 1) %>%
    dplyr::group_by(rid, ccle_name, culture, compound_plate) %>%
    dplyr::mutate(pass = pass & sum(pass, na.rm = T) / n_distinct(prism_replicate) > 0.5) %>%
    dplyr::ungroup()
  
} else {
  # add empty columns (so reports don't break)
  SSMD_TABLE %<>% dplyr::mutate(trt_poscon_md = NA,
                                trt_poscon_mad = NA,
                                error_rate = NA,
                                compound_plate = stringr::word(prism_replicate, 1,
                                                               sep = stringr::fixed("_")),
                                dr = NA,
                                pass = NA)
}

#---- Write data ----
# Write QC table
readr::write_csv(SSMD_TABLE, paste0(out_dir, "/SSMD_TABLE.csv"))

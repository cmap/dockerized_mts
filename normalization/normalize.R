# Script to run the initial processing step of the MTS pipeline
# creates logMFI and logMFI_NORMALIZED

# import necessary libraries and functions
suppressMessages(source("./src/normalization_functions.R"))

#---- Read arguments ----
script_args <- commandArgs(trailingOnly = TRUE)
if (length(script_args) != 3) {
  stop("Please supply path to data, output directory, and assay",
       call. = FALSE)
}
base_dir <- script_args[1]  # input directory
out_dir <- script_args[2]  # output directory
assay <- script_args[3]  # assay string (e.g. PR500)

if (!dir.exists(out_dir)) {dir.create(out_dir, recursive = T)}

# paths to data (make sure directory of data has these files)
path_data <- list.files(base_dir, pattern =  "*_LEVEL2_MFI*", full.names = T)
path_cell_info <- list.files(base_dir, pattern = "*_cell_info*", full.names = T)
path_inst_info <- list.files(base_dir, pattern = "*_inst_info*", full.names = T)

#---- Load the data ----

# read in logMFI data
raw_matrix <- read_hdf5(path_data)
rownames(raw_matrix) <- paste0(rownames(raw_matrix), "_", assay)

# read in cell line info
cell_info <- data.table::fread(path_cell_info) %>%
  dplyr::distinct(rid, ccle_name, pool_id) %>%
  dplyr::mutate(culture = assay) %>%
  dplyr::mutate(rid = paste0(rid, "_", assay)) %>%
  dplyr::mutate(pool_id = ifelse(pool_id == "" | pool_id == -666,
                                 "CTLBC", pool_id))

# make long version of platemap
inst_info <- data.table::fread(path_inst_info) %>%
  dplyr::filter(!str_detect(prism_replicate, "BASE"), !is_well_failure) %>%
  make_long_map(.) %>%
  dplyr::mutate(pert_dose = ifelse(pert_dose >= 0.001, round(pert_dose, 4), pert_dose),
                pert_idose = paste(pert_dose, word(pert_idose, 2)),
                pert_idose = ifelse(pert_idose == "NA NA", NA, pert_idose))

# change validation (.es) to treatment for processing
inst_info$pert_type[which(inst_info$pert_type == "trt_poscon.es")] <-
  "trt_cp"
inst_info$pert_type[which(inst_info$pert_type == "trt_cpd")] <-
  "trt_cp"

base_day <- data.table::fread(path_inst_info) %>%
  dplyr::filter(str_detect(prism_replicate, "BASE"), !is_well_failure)

if (nrow(base_day) > 0) {
  base_day %<>% dplyr::rename(pert_name = "pert_iname")
  if (!("pert_mfc_id") %in% colnames(base_day)){
    base_day %<>% dplyr::mutate(pert_mfc_id = pert_id)
  }
  base_day %<>% dplyr::select(intersect(colnames(.), colnames(inst_info)))
  inst_info %<>% dplyr::bind_rows(base_day)
}

# ensure unique profile IDs (this may cause problems for combo-perturbations)
raw_matrix <- raw_matrix[, inst_info$profile_id %>% unique()]

# melt matrix into data tables and join with inst and cell info
master_logMFI <- log2(raw_matrix) %>%
  reshape2::melt(varnames = c("rid", "profile_id"), value.name = "logMFI") %>%
  dplyr::filter(!is.na(logMFI)) %>%
  dplyr::inner_join(cell_info) %>%
  dplyr::inner_join(inst_info) %>%
  dplyr::select(profile_id, rid, ccle_name, pool_id, culture, prism_replicate, pert_time,
                pert_type, pert_dose, pert_idose, pert_mfc_id, pert_name, pert_well,
                logMFI, project_id)

compounds_logMFI <- master_logMFI %>%
  dplyr::filter(pert_type == "trt_cp")

controls_logMFI <- master_logMFI %>%
  dplyr::filter(pert_type != "trt_cp") %>%
  dplyr::mutate(project_id = "controls")

varied_compounds <- compounds_logMFI %>%
  dplyr::distinct(pert_name, pert_idose, project_id, prism_replicate) %>%
  dplyr::group_by(pert_name, project_id, prism_replicate) %>%
  dplyr::summarise(n = n(), .groups = "drop") %>%
  dplyr::filter(n > 1) %>%
  dplyr::mutate(full_curve = n > 4)

# handles multiple anchor doses
curve_comps <- varied_compounds %>%
  dplyr::filter(full_curve)
non_curve_comps <- varied_compounds %>%
  dplyr::filter(!full_curve | n > 9, n > 1)
compounds_logMFI %<>%
  dplyr::group_by(profile_id, rid, ccle_name, pool_id, culture, prism_replicate,
                  pert_type, pert_well, pert_time, logMFI, project_id) %>%
  dplyr::mutate(n = n()) %>%
  dplyr::ungroup()
comps_with_dose <- non_curve_comps %>%
  dplyr::select(-n) %>%
  dplyr::inner_join(compounds_logMFI) %>%
  dplyr::mutate(pert_name = ifelse(n > 1,
                                   paste(pert_name, pert_idose, sep = "_"),
                                   pert_name))
compounds_logMFI %<>%
  dplyr::anti_join(non_curve_comps %>% dplyr::select(-n)) %>%
  dplyr::bind_rows(comps_with_dose)

compounds_logMFI %<>%
  dplyr::group_by(profile_id, rid, ccle_name, pool_id, culture, prism_replicate,
                  pert_type, pert_well, pert_time, logMFI, project_id, n) %>%
  dplyr::summarise(pert_dose = ifelse(any(pert_name %in% curve_comps$pert_name),
                                      pert_dose[pert_name %in% curve_comps$pert_name],
                                      pert_dose),
                   pert_idose = ifelse(any(pert_name %in% curve_comps$pert_name),
                                       pert_idose[pert_name %in% curve_comps$pert_name],
                                       pert_idose),
                   pert_mfc_id = ifelse(any(pert_name %in% curve_comps$pert_name),
                                        pert_mfc_id[pert_name %in% curve_comps$pert_name],
                                        pert_mfc_id),
                   pert_name = paste(sort(unique(pert_name)), collapse = "_"),
                   .groups = "drop") %>%
  dplyr::select(-n)

master_logMFI <- dplyr::bind_rows(compounds_logMFI, controls_logMFI)

# create barcode tables
barcodes <- master_logMFI %>%
  dplyr::filter(pool_id == "CTLBC")

# filter base plates
logMFI_base <- master_logMFI %>%
  dplyr::filter(str_detect(prism_replicate, "BASE"))
master_logMFI %<>%
  dplyr::filter(!str_detect(prism_replicate, "BASE"))

#---- Normalize ----

# compute control barcode median of medians for normalization
logMFI_control_medians <- control_medians(master_logMFI %>%
                                            dplyr::filter(is.finite(logMFI)))

# fit curve to controls and predict test conditions
logMFI_normalized <- normalize(logMFI_control_medians, barcodes)

# if there is an early measurement
if(nrow(logMFI_base) > 0) {
  # generate reference profile to normalize base data
  logMFI_profile <- logMFI_normalized %>%
    dplyr::filter(rid %in% barcodes$rid) %>%
    dplyr::group_by(rid) %>%
    dplyr::mutate(rLMFI = mean(rLMFI)) %>%
    dplyr::ungroup() %>%
    dplyr::distinct(rid, rLMFI)

  base_normalized <- logMFI_base %>%
    dplyr::left_join(logMFI_profile) %>%
    normalize(., barcodes)
} else {
  base_normalized <- tibble()
}

# join with other info (LMFI is normalized, logMFI is not)
logMFI_normalized %<>%
  dplyr::left_join(master_logMFI) %>%
  dplyr::select(-logMFI)

#---- Write data ----
master_logMFI %>%
  dplyr::bind_rows(logMFI_base) %>%
  readr::write_csv(., paste0(out_dir, "/logMFI.csv"))
logMFI_normalized %>%
  dplyr::bind_rows(base_normalized) %>%
  dplyr::select(-rLMFI) %>%
  readr::write_csv(., paste0(out_dir, "/logMFI_NORMALIZED.csv"))

# project key
write_key(master_logMFI, out_dir)

library(hdf5r)

# import necessary libraries and functions using MTS_functions.R
suppressMessages(source("./src/MTS_functions.R"))

# script takes the name of the directory where data is stored as arg
script_args <- commandArgs(trailingOnly = TRUE)
if (length(script_args) != 2) {
  stop("Please supply path to data directory and output folder", call. = FALSE)
}

# directory with data
base_dir <- script_args[1]
# output directory
out_dir <- script_args[2]
if (!dir.exists(out_dir)) {dir.create(out_dir)}

# paths to data (make sure directory of data has these files)
path_key <- paste0(base_dir, "/project_key.csv")
path_500 <- paste0(base_dir, "/PR500_MFI.gctx")
path_300 <- paste0(base_dir, "/PR300_MFI.gctx")
path_platemap <- paste0(base_dir, "/platemap.csv")  # PRISM platemap
path_cell_info_500 <- paste0(base_dir, "/PR500_cell_info.csv")
path_cell_info_300 <- paste0(base_dir, "/PR300_cell_info.csv")
path_inst_info_500 <- paste0(base_dir, "/PR500_inst_info.txt")  # CMap platemap
path_inst_info_300 <- paste0(base_dir, "/PR300_inst_info.txt")  # CMap platemap

# HDF5 file reader
read_hdf5 = function (filename, index = NULL) {
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


#---- Load the data ----

# data table linking drugs to projects (collaborators)
key_table <- data.table::fread(path_key)

# read in logMFI data
PR500 <- read_hdf5(path_500)
PR300 <- read_hdf5(path_300)
rownames(PR500) = paste0(rownames(PR500), "_", "PR500")
rownames(PR300) = paste0(rownames(PR300), "_", "PR300")

# read in cell line info
cell_info_500 <- data.table::fread(path_cell_info_500) %>%
  dplyr::distinct(rid, ccle_name, pool_id) %>%
  dplyr::mutate(culture = "PR500") %>%
  dplyr::mutate(rid = paste0("c-", rid, "_", culture)) %>%
  dplyr::mutate(pool_id = ifelse(pool_id == "" | pool_id == -666,
                                 "CTLBC", pool_id))

cell_info_300 <- data.table::fread(path_cell_info_300) %>%
  dplyr::distinct(rid, ccle_name, pool_id) %>%
  dplyr::mutate(culture = "PR300") %>%
  dplyr::mutate(rid = paste0("c-", rid, "_", culture)) %>%
  dplyr::mutate(pool_id = ifelse(pool_id == "" | pool_id == -666,
                                 "CTLBC", pool_id))

# read in PRISM assay info
platemap <- data.table::fread(path_platemap)

# combine with CMap assay info
inst_info_500 <- data.table::fread(path_inst_info_500) %>%
  dplyr::filter(!is_well_failure) %>%
  dplyr::distinct(profile_id, x_mapping, pert_plate, prism_replicate, pert_well, is_well_failure) %>%
  dplyr::rename(cmap_plate = pert_plate) %>%
  dplyr::inner_join(platemap) %>%
  dplyr::mutate(prism_replicate = paste(cmap_plate,
                                        word(prism_replicate, -2, -1, sep = "_"),
                                        paste0(lysis_day * 24, "H"),
                                        sep = "_"))
base_day500 <- data.table::fread(path_inst_info_500) %>%
  dplyr::filter(!is_well_failure, str_detect(prism_replicate, "BASE")) %>%
  dplyr::select(profile_id, pert_dose, pert_idose, pert_iname, pert_mfc_id,
                pert_type, pert_plate, pert_well, x_mapping, is_well_failure,
                prism_replicate, pert_dose_unit, pert_time) %>%
  dplyr::rename(cmap_plate = pert_plate) %>%
  dplyr::mutate(prism_replicate = paste(cmap_plate,
                                        word(prism_replicate, -2, -1, sep = "_"),
                                        pert_time,
                                        sep = "_")) %>%
  dplyr::select(-pert_time)
inst_info_500 %<>% dplyr::bind_rows(base_day500)

# combine with CMap assay info
inst_info_300 <- data.table::fread(path_inst_info_300) %>%
  dplyr::filter(!is_well_failure) %>%
  dplyr::distinct(profile_id, x_mapping, pert_plate, prism_replicate, pert_well, is_well_failure) %>%
  dplyr::rename(cmap_plate = pert_plate) %>%
  dplyr::inner_join(platemap) %>%
  dplyr::mutate(prism_replicate = paste(cmap_plate,
                                        word(prism_replicate, -2, -1, sep = "_"),
                                        paste0(lysis_day * 24, "H"),
                                        sep = "_"))
base_day300 <- data.table::fread(path_inst_info_300) %>%
  dplyr::filter(!is_well_failure, str_detect(prism_replicate, "BASE")) %>%
  dplyr::select(profile_id, pert_dose, pert_idose, pert_iname, pert_mfc_id,
                pert_type, pert_plate, pert_well, x_mapping, is_well_failure,
                prism_replicate, pert_dose_unit, pert_time) %>%
  dplyr::rename(cmap_plate = pert_plate) %>%
  dplyr::mutate(prism_replicate = paste(cmap_plate,
                                        word(prism_replicate, -2, -1, sep = "_"),
                                        pert_time,
                                        sep = "_")) %>%
  dplyr::select(-pert_time)
inst_info_300 %<>% dplyr::bind_rows(base_day300)

# ensure unique profile IDs (this may cause problems for combo-perturbations)
PR500 <- PR500[, inst_info_500$profile_id %>% unique()]
PR300 <- PR300[, inst_info_300$profile_id %>% unique()]

# melt matrices into data tables and join with inst and cell info
PR500_molten <- log2(PR500) %>%
  reshape2::melt(varnames = c("rid", "profile_id"), value.name = "logMFI") %>%
  dplyr::inner_join(cell_info_500) %>%
  dplyr::inner_join(inst_info_500)

PR300_molten <- log2(PR300) %>%
  reshape2::melt(varnames = c("rid", "profile_id"), value.name = "logMFI") %>%
  dplyr::inner_join(cell_info_300) %>%
  dplyr::inner_join(inst_info_300)

# bind tables together (reorder columns)
master_logMFI <- PR500_molten %>%
  dplyr::bind_rows(PR300_molten) %>%
  dplyr::mutate(pert_name = pert_iname) %>%
  dplyr::select(profile_id, rid, ccle_name, pool_id, culture, prism_replicate,
                pert_type, pert_dose, pert_idose, pert_mfc_id, pert_name, pert_well,
                logMFI)

# change validation (.es) to treatment for processing
master_logMFI$pert_type[which(master_logMFI$pert_type == "trt_poscon.es")] <-
  "trt_cp"
master_logMFI$pert_type[which(master_logMFI$pert_type == "trt_cpd")] <-
  "trt_cp"

# write day 0 to own folder
master_logMFI %>%
  dplyr::filter(str_detect(prism_replicate, "BASE")) %>%
  {if(nrow(.) > 0) readr::write_csv(., paste0(base_dir, "/",
                                              basename(base_dir), "_BASE.csv"))}

# separate out controls (included in all projects)
controls <- master_logMFI %>%
  dplyr::filter(pert_type %in% c("ctl_vehicle", "trt_poscon"))

readr::write_csv(controls, paste0(out_dir,"/controls_logMFI.csv"))

# list of projects
projects <- key_table %>%
  dplyr::distinct(project_id)

#---- Separate projects ----
# loop through each project and generate .csv of its data
for (i in 1:nrow(projects)) {
  project <- projects[[i,1]]
  project_dir <- stringr::str_replace_all(project, "[[:punct:]\\s]+", "_")
  project_data <- key_table %>%
    dplyr::filter(project_id == project) %>%
    dplyr::select(pert_name) %>%
    dplyr::left_join(master_logMFI, by = "pert_name")

  if (!dir.exists(paste0(out_dir, "/", project_dir))) {
    dir.create(paste0(out_dir, "/", project_dir))
  }

  readr::write_csv(project_data, paste0(out_dir, "/", project_dir, "/logMFI.csv"))
}

#---- Generate QC metrics ----
#---- Normalize ----

# split into 300 and 500 sets
PR300 <- controls %>%
  dplyr::filter(culture == "PR300", !str_detect(prism_replicate, "BASE"))
PR500 <- controls %>%
  dplyr::filter(culture == "PR500", !str_detect(prism_replicate, "BASE"))

# create barcode tables
PR300_barcodes <- PR300 %>%
  dplyr::filter(pool_id == "CTLBC")
PR500_barcodes <- PR500 %>%
  dplyr::filter(pool_id == "CTLBC")

# compute control barcode median of medians for normalization
PR300_control_medians <- control_medians(PR300)
# fit curve to controls and predict test conditions
PR300_normalized <- normalize(PR300_control_medians, PR300_barcodes)
# join with other info (LMFI is normalized, logMFI is not)
PR300_normalized %<>%
  dplyr::left_join(PR300) %>%
  dplyr::select(-logMFI)
# repeat with PR500
PR500_control_medians <- control_medians(PR500)
PR500_normalized <- normalize(PR500_control_medians, PR500_barcodes)
PR500_normalized %<>%
  dplyr::left_join(PR500) %>%
  dplyr::select(-logMFI)

#---- Calculate QC metrics ----
# calculate SSMD and NNMD
SSMD_table_300 <- calc_ssmd(PR300_normalized %>%
                              dplyr::filter(pool_id != "CTLBC"))
# calculate error rate of normalized table (based on threshold classifier)
PR300_error <- PR300_normalized %>%
  dplyr::filter(is.finite(LMFI), pool_id != "CTLBC") %>%
  dplyr::group_by(rid, ccle_name, prism_replicate) %>%
  dplyr::summarize(error_rate =
                     min(PRROC::roc.curve(scores.class0 = LMFI,
                                          weights.class0 = pert_type == "ctl_vehicle",
                                          curve = TRUE)$curve[,1] + 1 -
                           PRROC::roc.curve(scores.class0 = LMFI,
                                            weights.class0 = pert_type == "ctl_vehicle",
                                            curve = TRUE )$curve[,2])/2)
# join with SSMD table
SSMD_table_300 <- SSMD_table_300 %>%
  dplyr::left_join(PR300_error)
# REPEAT with 500
SSMD_table_500 <- calc_ssmd(PR500_normalized %>% dplyr::filter(pool_id != "CTLBC"))
PR500_error <- PR500_normalized %>%
  dplyr::filter(is.finite(LMFI), pool_id != "CTLBC") %>%
  dplyr::group_by(rid, ccle_name, prism_replicate) %>%
  dplyr::summarize(error_rate =
                     min(PRROC::roc.curve(scores.class0 = LMFI,
                                          weights.class0 = pert_type == "ctl_vehicle",
                                          curve = TRUE)$curve[,1] + 1 -
                           PRROC::roc.curve(scores.class0 = LMFI,
                                            weights.class0 = pert_type == "ctl_vehicle",
                                            curve = TRUE )$curve[,2])/2)
SSMD_table_500 <- SSMD_table_500 %>%
  dplyr::left_join(PR500_error)

# combine 300 and 500 tables
SSMD_TABLE <- dplyr::bind_rows(SSMD_table_500, SSMD_table_300) %>%
  # if error rate <= .05 then pass
  dplyr::mutate(pass = error_rate <= 0.05,
                compound_plate =  stringr::word(prism_replicate, 1,
                                                sep = stringr::fixed("_"))) %>%
  dplyr::filter(pool_id != "CTLBC") %>%
  dplyr::ungroup()

#---- Write output ----
readr::write_csv(SSMD_TABLE, paste0(out_dir, "/SSMD_TABLE.csv"))
controls_MFI_norm <- PR300_normalized %>%
  dplyr::bind_rows(PR500_normalized)
readr::write_csv(controls_MFI_norm, paste0(out_dir, "/controls_logMFI_NORMALIZED.csv"))

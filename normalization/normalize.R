# Script to run the initial processing step of the MTS pipeline
# creates logMFI and logMFI_NORMALIZED

# import necessary libraries and functions
suppressMessages(source("./src/normalization_functions.R"))

#---- Read arguments ----

parser <- ArgumentParser()
# specify our desired options
parser$add_argument("-b", "--base_dir", default="", help="Input Directory")
parser$add_argument("-o", "--out", default=getwd(), help = "Output path. Default is working directory")
parser$add_argument("-a", "--assay", default="", help="Assay string (e.g. PR500)")
parser$add_argument("-n", "--name", default="", help="Build name. Default is none")

# get command line options, if help option encountered print help and exit
args <- parser$parse_args()

base_dir <- args$base_dir
out_dir <- args$out
assay <- args$assay
build_name <- args$name

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

<<<<<<< HEAD
# make long version of platemap
inst_info <- data.table::fread(path_inst_info) %>%
  dplyr::filter(!str_detect(prism_replicate, "BASE"), !is_well_failure) %>%
  make_long_map(.) %>%
  dplyr::mutate(pert_dose = ifelse(pert_dose >= 0.001, round(pert_dose, 4), pert_dose),
                pert_idose = paste(pert_dose, word(pert_idose, 2)),
                pert_idose = ifelse(pert_idose == "NA NA", NA, pert_idose))

# change validation (.es) to treatment for processing
inst_info$pert_type[which(str_detect(inst_info$pert_type, "poscon.es"))] <-
  "trt_cp"
inst_info$pert_type[which(inst_info$pert_type == "trt_cpd")] <-
  "trt_cp"
=======
# read in inst_info
inst_info <- data.table::fread(path_inst_info)
>>>>>>> dev

# split out base plate
base_day <- data.table::fread(path_inst_info) %>%
  dplyr::filter(str_detect(prism_replicate, "BASE"))

# ensure unique profile IDs
raw_matrix <- raw_matrix[, inst_info$profile_id %>% unique()]

# melt matrix into data tables and join with inst and cell info
master_logMFI <- log2(raw_matrix) %>%
  reshape2::melt(varnames = c("rid", "profile_id"), value.name = "logMFI") %>%
  dplyr::filter(is.finite(logMFI)) %>%
  dplyr::inner_join(cell_info) %>%
<<<<<<< HEAD
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
if (nrow(non_curve_comps) > 0) {
  comps_with_dose <- non_curve_comps %>%
    dplyr::select(-n) %>%
    dplyr::inner_join(compounds_logMFI) %>%
    dplyr::mutate(pert_name = ifelse(n > 1,
                                     paste(pert_name, pert_idose, sep = "_"),
                                     pert_name))
  compounds_logMFI %<>%
    dplyr::anti_join(non_curve_comps %>% dplyr::select(-n)) %>%
    dplyr::bind_rows(comps_with_dose)
}

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
=======
  dplyr::inner_join(inst_info)
>>>>>>> dev

# create barcode tables
barcodes <- master_logMFI %>%
  dplyr::filter(pool_id == "CTLBC")

if (nrow(barcodes) == 0) stop("No control barcodes detected. Unable to normalize")

# filter base plates
logMFI_base <- master_logMFI %>%
  dplyr::filter(str_detect(prism_replicate, "BASE"))
master_logMFI %<>%
  dplyr::filter(!str_detect(prism_replicate, "BASE"))

#---- Normalize ----

# compute control barcode median of medians for normalization
logMFI_control_medians <- control_medians(master_logMFI %>%
                                            dplyr::filter(is.finite(logMFI),
                                                          logMFI != 0))

# fit curve to controls and predict test conditions
logMFI_normalized <- normalize(logMFI_control_medians, barcodes, nrow(cell_info) / 2)

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
    dplyr::filter(is.finite(logMFI), logMFI != 0) %>%
    dplyr::left_join(logMFI_profile) %>%
    normalize_base(., barcodes, nrow(cell_info) / 2)
} else {
  base_normalized <- tibble()
}

# join with other info (LMFI is normalized, logMFI is not)
logMFI_normalized %<>%
  dplyr::left_join(master_logMFI)

#---- Write data ----
logMFI_normalized %>%
  dplyr::bind_rows(base_normalized) %>%
  dplyr::select(-rLMFI) %>%
  readr::write_csv(., paste0(out_dir, "/", build_name, "_LEVEL3_LMFI.csv"))

# compound key
write_key(logMFI_normalized, out_dir, build_name)

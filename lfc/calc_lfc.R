# Script to go from normalized logMFI values to LFC

# import necessary libraries and functions using MTS_functions.R
suppressMessages(source("./src/lfc_functions.R"))

#---- Read arguments ----
# initialize parser
parser <- ArgumentParser()

# specify our desired options
parser$add_argument("-b", "--base_dir", default=getwd(), help="Input directory. Default is working directory")
parser$add_argument("-o", "--out", default=getwd(), help = "Output path. Default is working directory")
parser$add_argument("-n", "--name", default="", help = "Build name. Default is none")

# get command line options, if help option encountered print help and exit
args <- parser$parse_args()

base_dir <- args$base_dir
out_dir <- args$out
build_name <- args$name

if (!dir.exists(out_dir)) {dir.create(out_dir, recursive = T)}

#---- Load the data ----
print("Loading data and pre-processing")
logMFI_files <- list.files(base_dir, pattern = "LEVEL3_LMFI", full.names = T)
if (length(logMFI_files) == 1) {
  logMFI_normalized <- data.table::fread(logMFI_files[[1]])
} else {
  stop(paste("There are", length(logMFI_files), "level 3 tables in this directory. Please ensure there is one and try again."),
       call. = FALSE)
}

# split into base and final reading
base_normalized <- logMFI_normalized %>%
  dplyr::filter(str_detect(prism_replicate, "BASE"))
logMFI_normalized %<>%
  dplyr::filter(str_detect(prism_replicate, "BASE", negate = T))

qc_files <- list.files(base_dir, pattern = "QC_TABLE", full.names = T)
if (length(qc_files) == 1) {
  qc_table <- data.table::fread(qc_files[[1]]) %>%
    dplyr::filter(prism_replicate %in% plates$prism_replicate)
} else {
  stop(paste("There are", length(qc_files), "QC tables in this directory. Please ensure there is one and try again."),
       call. = FALSE)
}

#---- Compute log-fold changes ----
print("Calculating log-fold changes")
LFC_TABLE <- logMFI_normalized
# if QC able to be applied
if (!all(is.na(qc_table$pass))) {
  LFC_TABLE %<>%
    # join with SSMD (to filter bad lines)
    dplyr::inner_join(qc_table %>%
                        dplyr::distinct(ccle_name, prism_replicate, culture, pass),
                      by = c("prism_replicate", "ccle_name", "culture")) %>%
    dplyr::filter(pass) %>%
    dplyr::select(-pass)
} else {
  print("Problem with QC metrics: including all lines")
}
LFC_TABLE <- calculate_lfc(LFC_TABLE)

#---- Make collapsed LFC table ----
LFC_COLLAPSED_TABLE <- LFC_TABLE %>%
  dplyr::select(ccle_name, culture, pool_id, pert_iname, pert_id, pert_dose,
                pert_idose, compound_plate, pert_vehicle, pert_time, LFC,
                any_of(c("x_mixture_contents", "x_mixture_id", "x_project_id"))) %>%
  dplyr::group_by(across(.cols = !contains("LFC"))) %>%
  # LFC and LFC.cb values will be medians across replicates
  dplyr::summarise(LFC = median(LFC, na.rm = T))

#---- Write results ----
readr::write_csv(LFC_TABLE, paste0(out_dir, "/", build_name, "_LEVEL4_LFC.csv"))
readr::write_csv(LFC_COLLAPSED_TABLE, paste0(out_dir, "/", build_name, "_LEVEL5_LFC.csv"))

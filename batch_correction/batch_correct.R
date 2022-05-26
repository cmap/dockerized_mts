# Script to go from normalized logMFI values to LFC

# import necessary libraries and functions using MTS_functions.R
suppressMessages(source("./src/batch_correct_functions.R"))

#---- Read arguments ----
# initialize parser
parser <- ArgumentParser()
# specify our desired options
parser$add_argument("-b", "--base_dir", default="", help="Input directory")
parser$add_argument("-o", "--out", default=getwd(), help = "Output path. Default is working directory")
parser$add_argument("-n", "--name", default="", help = "Build name. Default is none")

# get command line options, if help option encountered print help and exit
args <- parser$parse_args()

base_dir <- args$base_dir
out_dir <- args$out
build_name <- args$name

if (!dir.exists(out_dir)) {dir.create(out_dir, recursive = T)}

#---- Load the data ----
print("Loading the data")
LFC_files <- list.files(base_dir, pattern = "LEVEL4_LFC", full.names = T)
if (length(LFC_files) == 1) {
  LFC_TABLE <- data.table::fread(LFC_files[[1]])
} else {
  stop(paste("There are", length(LFC_files), "level 4 tables in this directory. Please ensure there is one and try again."),
       call. = FALSE)
}

#---- Correct for pool effects ----
print("ComBat correcting")
LFC_TABLE %<>%
  dplyr::filter(!pert_type %in% c("ctl_vehicle", "ctl_untrt"), is.finite(LFC)) %>%
  tidyr::unite(col = "condition", pert_iname, pert_dose, pert_plate, pert_time, pert_vehicle, any_of("x_project_id"),
               sep = "::", remove = FALSE) %>%
  split(.$condition) %>%
  purrr::map_dfr(~dplyr::mutate(.x, LFC_cb = apply_combat(.))) %>%
  dplyr::select(-condition)

#---- Make collapsed LFC table ----
LFC_COLLAPSED_TABLE <- LFC_TABLE %>%
  dplyr::mutate(sig_id = paste(pert_plate, culture, pert_id, pert_idose, pert_time, sep = fixed("_"))) %>%
  dplyr::select(rid, ccle_name, culture, pool_id, pert_iname, pert_id, pert_dose,
                pert_idose, pert_plate, pert_vehicle, pert_time, pert_type, LFC, LFC_cb, sig_id,
                any_of(c("x_mixture_contents", "x_mixture_id", "x_project_id"))) %>%
  dplyr::group_by(across(.cols = !contains("LFC"))) %>%
  # LFC and LFC_cb values will be medians across replicates
  dplyr::summarize(LFC = median(LFC, na.rm = TRUE),
                   LFC_cb = median(LFC_cb, na.rm = TRUE),
                   .groups = "drop")

dims_full = paste(dplyr::distinct(LFC_TABLE, profile_id) %>% nrow(),
                  dplyr::distinct(LFC_TABLE, rid) %>% nrow(),
                  sep = "x")
dims_coll = paste(dplyr::distinct(LFC_COLLAPSED_TABLE, sig_id) %>% nrow(),
                  dplyr::distinct(LFC_COLLAPSED_TABLE, rid) %>% nrow(),
                  sep = "x")

#---- Write results ----
readr::write_csv(LFC_TABLE, paste0(out_dir, "/", build_name, "_LEVEL4_LFC_COMBAT_n", dims_full, ".csv"))
readr::write_csv(LFC_COLLAPSED_TABLE, paste0(out_dir, "/", build_name, "_LEVEL5_LFC_COMBAT_n", dims_coll, ".csv"))

# Script to run the QC step of the MTS pipeline
# creates SSMD_TABLE

# import necessary libraries and functions
suppressMessages(source("./src/qc_functions.R"))

#---- Read arguments ----
# initialize parser
parser <- ArgumentParser()
# specify our desired options
parser$add_argument("-b", "--base_dir", default="", help="Input Directory")
parser$add_argument("-o", "--out", default=getwd(), help = "Output path. Default is working directory")
parser$add_argument("-n", "--name", default="", help = "Build name. Default is none")

# get command line options, if help option encountered print help and exit
args <- parser$parse_args()

base_dir <- args$base_dir
out_dir <- args$out
build_name <- args$name

if (!dir.exists(out_dir)) {dir.create(out_dir, recursive = T)}

# paths to data (make sure directory of data has these files)
path_data <- paste0(base_dir, "/logMFI.csv")

#---- Load the data ----
print("Loading data")

logMFI_files <- list.files(base_dir, pattern = "LEVEL3_LMFI", full.names = T)
if (length(logMFI_files) == 1) {
  logMFI_normalized <- data.table::fread(logMFI_files[[1]])
} else {
  stop(paste("There are", length(logMFI_files), "level 3 tables in this directory. Please ensure there is one and try again."),
       call. = FALSE)
}

#---- Calculate QC metrics ----
print("Calculating SSMDs")

# calculate SSMD and NNMD (allow for no QC)
qc_table <- calc_ssmd(logMFI_normalized %>% dplyr::filter(pool_id != "CTLBC"))
if (any(is.na(qc_table$ssmd))) {
  message("Unable to calculate some QC metrics: control condition(s) may be missing")
}

# if there are positive controls
if ("trt_poscon_md" %in% colnames(qc_table)) {

  # calculate error rate of normalized table (based on threshold classifier)
  print("Calculating error rates")
  error_table <- calc_er(logMFI_normalized)

  # join with SSMD table
  qc_table %<>%
    dplyr::left_join(error_table, by = c("prism_replicate", "pert_plate", "ccle_name", "rid", "culture", "pert_vehicle", "barcode_id")) %>%
    dplyr::mutate(dr = ctl_vehicle_md - trt_poscon_md,
                  pass = error_rate <= 0.05 & dr > -log2(0.3)) 

} else {
  # add empty columns (so reports don't break)
  qc_table %<>% dplyr::mutate(trt_poscon_md = NA,
                                trt_poscon_mad = NA,
                                error_rate = NA,
                                pert_plate = stringr::word(prism_replicate, 1,
                                                               sep = stringr::fixed("_")),
                                dr = NA,
                              pass = NA)
}

# Calculate floor range metric and merge
fr_table <- make_fr_table(logMFI_normalized)
qc_table <- qc_table %>%
  dplyr::left_join(fr_table, by = c("prism_replicate", "ccle_name", "barcode_id"))

# Update flags
qc_table <- qc_table %>%
  dplyr::rename(pass_dr_er = pass) %>%
  dplyr::mutate(pass = pass_dr_er & pass_fr)

qc_table <- qc_table %>%
  dplyr::group_by(rid, ccle_name, culture, pert_plate) %>%
  dplyr::mutate(pass = pass & sum(pass, na.rm = T) / n_distinct(prism_replicate) > 0.5) %>%
  dplyr::ungroup()


#---- Write data ----
# Write QC table
write.csv(qc_table, paste0(out_dir, "/", build_name, "_QC_TABLE.csv"), row.names=FALSE)

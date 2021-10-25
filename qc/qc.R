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

# read in normalized logMFI data
logMFI_normalized <- data.table::fread(path_data)

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
    dplyr::left_join(error_table, by = c("prism_replicate", "ccle_name", "rid", "culture")) %>%
    dplyr::mutate(compound_plate = stringr::word(prism_replicate, 1,
                                                 sep = stringr::fixed("_")),
                  dr = ctl_vehicle_md - trt_poscon_md,
                  pass = error_rate <= 0.05 & dr > -log2(0.3)) %>%
    dplyr::group_by(rid, ccle_name, culture, compound_plate) %>%
    dplyr::mutate(pass = pass & sum(pass, na.rm = T) / n_distinct(prism_replicate) > 0.5) %>%
    dplyr::ungroup()

} else {
  # add empty columns (so reports don't break)
  qc_table %<>% dplyr::mutate(trt_poscon_md = NA,
                                trt_poscon_mad = NA,
                                error_rate = NA,
                                compound_plate = stringr::word(prism_replicate, 1,
                                                               sep = stringr::fixed("_")),
                                dr = NA,
                                pass = NA)
}

#---- Write data ----
# Write QC table
readr::write_csv(qc_table, paste0(out_dir, "/", build_name, "QC_TABLE.csv"))

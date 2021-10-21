# Script to go from normalized logMFI values to LFC

# import necessary libraries and functions using MTS_functions.R
suppressMessages(source("./src/lfc_functions.R"))

#---- Read arguments ----
# initialize parser
parser <- ArgumentParser()

# specify our desired options
parser$add_argument("-b", "--base_dir", default="", help="Input directory")
parser$add_argument("-o", "--out", default=getwd(), help = "Output path. Default is working directory")

# get command line options, if help option encountered print help and exit
args <- parser$parse_args()

base_dir <- args$base_dir
out_dir <- args$out

if (!dir.exists(out_dir)) {dir.create(out_dir, recursive = T)}

#---- Load the data ----
print("Loading data and pre-processing")
logMFI_normalized <- data.table::fread(paste0(base_dir, "/logMFI.csv"))

# split into base and final reading
base_normalized <- logMFI_normalized %>%
  dplyr::filter(str_detect(prism_replicate, "BASE"))
logMFI_normalized %<>%
  dplyr::filter(str_detect(prism_replicate, "BASE", negate = T))
qc_table <- data.table::fread(paste0(base_dir, "/QC_table.csv")) %>%
  dplyr::filter(prism_replicate %in% plates$prism_replicate)

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

#---- Write results ----
readr::write_csv(LFC_TABLE, paste0(out_dir, "/LFC_TABLE.csv"))

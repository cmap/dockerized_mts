# Script to make DepMap compatible matrices

# import necessary libraries and functions using MTS_functions.R
suppressMessages(source("./src/depmap_functions.R"))

#---- Read arguments ----

parser <- ArgumentParser()
# specify our desired options
parser$add_argument("-p", "--project_dir", default="", help="Project directory")
parser$add_argument("-o", "--out", default="", help="Output directory")

# get command line options, if help option encountered print help and exit
args <- parser$parse_args()

proj_dir <- args$project_dir
out_dir <- args$out

# get paths to LFC and DRC
lfc_path <- list.files(proj_dir, pattern = "LEVEL5_LFC_COMBAT", full.names = T)
stopifnot(length(lfc_path) == 1)  # need LFC
drc_path <- list.files(proj_dir, pattern = "DRC_TABLE", full.names = T)

# read in LFC
lfc_tab <- data.table::fread(lfc_path) %>%
  dplyr::filter(!is.na(ccle_name), pool_id != "CTLBC",
                str_detect(ccle_name, "prism invariant", negate = T))
# pivot
lfc_mat <- reshape2::acast(lfc_tab, ccle_name ~ pert_iname + pert_idose,
                           value.var = "LFC_cb",
                           fun.aggregate = function(x) mean(x, na.rm = TRUE))
# write LFC
write.csv(lfc_mat, paste0(out_dir, "LFC_MATRIX.csv"))

# do the same for DRC if it exists (make AUC and IC50 matrix)
if (length(drc_path) == 1) {
  drc_tab <- data.table::fread(drc_path) %>%
    dplyr::filter(!is.na(ccle_name),
                  str_detect(ccle_name, "prism invariant", negate = T)) %>%
    dplyr::mutate(condition = ifelse("added_compounds" %in% colnames(.),
                                     paste(varied_iname, added_compounds, added_doses),
                                     varied_iname))
  auc_mat <- reshape2::acast(drc_tab, ccle_name ~ condition,
                             value.var = "auc",
                             fun.aggregate = function(x) mean(x, na.rm = TRUE))
  ic50_mat <- reshape2::acast(drc_tab, ccle_name ~ condition,
                              value.var = "log2.ic50",
                              fun.aggregate = function(x) mean(x, na.rm = TRUE))

  write.csv(auc_mat, paste0(out_dir, "/AUC_MATRIX.csv"))
  write.csv(ic50_mat, paste0(out_dir, "/IC50_MATRIX.csv"))
}

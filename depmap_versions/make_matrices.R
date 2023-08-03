# Script to make DepMap compatible matrices

# import necessary libraries and functions using MTS_functions.R
suppressMessages(source("./src/depmap_functions.R"))

#---- Read arguments ----

parser <- ArgumentParser()
# specify our desired options
parser$add_argument("-p", "--project_dir", default="", help="Project directory")
parser$add_argument("-o", "--out", default="", help="Output directory")
parser$add_argument("-n", "--name", default="", help = "Build name. Default is none")

# get command line options, if help option encountered print help and exit
args <- parser$parse_args()

proj_dir <- args$project_dir
out_dir <- args$out
build_name <- args$name

# get paths to LFC and DRC
lfc_path <- list.files(proj_dir, pattern = "LEVEL5_LFC_COMBAT", full.names = T)
stopifnot(length(lfc_path) == 1)  # need LFC
drc_path <- list.files(proj_dir, pattern = "DRC_TABLE", full.names = T)

print("line 26")
# read in LFC
lfc_tab <- data.table::fread(lfc_path) %>%
  dplyr::filter(!is.na(ccle_name), pool_id != "CTLBC",
                str_detect(ccle_name, "prism invariant", negate = T))
print("line 31")
# pivot
lfc_mat <- reshape2::acast(lfc_tab, ccle_name ~ pert_iname + pert_idose,
                           value.var = "LFC_cb",
                           fun.aggregate = function(x) mean(x, na.rm = TRUE))
# write LFC
write.csv(lfc_mat, paste0(out_dir, "/", build_name, "_LFC_MATRIX.csv"))

print("line 39")
# do the same for DRC if it exists (make AUC and IC50 matrix)
if (length(drc_path) == 1) {
  drc_tab <- data.table::fread(drc_path) %>%
    dplyr::filter(!is.na(ccle_name),
                  str_detect(ccle_name, "prism invariant", negate = T)) %>%
    dplyr::mutate(condition = varied_iname)
  print("line 46")
  if ("added_compounds" %in% colnames(drc_tab)) {
    drc_tab$condition <- paste(drc_tab$condition, drc_tab$added_compounds, drc_tab$added_doses, sep = "_")
  }
  auc_mat <- reshape2::acast(drc_tab, ccle_name ~ condition,
                             value.var = "auc",
                             fun.aggregate = function(x) mean(x, na.rm = TRUE))
  ic50_mat <- reshape2::acast(drc_tab, ccle_name ~ condition,
                              value.var = "log2.ic50",
                              fun.aggregate = function(x) mean(x, na.rm = TRUE))

  write.csv(auc_mat, paste0(out_dir, "/", build_name, "_AUC_MATRIX.csv"))
  write.csv(ic50_mat, paste0(out_dir, "/", build_name, "_IC50_MATRIX.csv"))
}

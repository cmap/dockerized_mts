# Script to go from LFC to DRC

# import necessary libraries and functions using MTS_functions.R
suppressMessages(source("./src/drc_functions.R"))

#---- Read arguments ----

parser <- ArgumentParser()
# specify our desired options
parser$add_argument("-i", "--input_file", default="", help="Input level 4 (LFC) file")
parser$add_argument("-o", "--out", default="", help="Output directory")

# get command line options, if help option encountered print help and exit
args <- parser$parse_args()

lfc_file <- args$input_file
out_dir <- args$out

#---- Load the data ----
print("Loading data and pre-processing")
LFC_TABLE <- data.table::fread(lfc_file)

#---- Compute dose-response parameters ----
# table with each compound cell line combo and number of doses
DRC_TABLE_cb <- LFC_TABLE %>%
  dplyr::distinct(ccle_name, culture, pert_mfc_id, pert_name, pert_dose, pert_time, compound_plate) %>%
  dplyr::count(ccle_name, culture, pert_mfc_id, pert_name, pert_time) %>%
  dplyr::filter(n > 3)  # only fit curves with 4+ doses

if (nrow(DRC_TABLE_cb > 0)) {
  print("Fitting dose-response curves")
  DRC_TABLE_cb %<>% dplyr::mutate(ix = 1:n())
  DRC_cb <- list()  # empty tibble to track results

  # loop through compound cell line combos fitting curves
  for (jx in 1:nrow(DRC_TABLE_cb)) {
    d = DRC_TABLE_cb %>%
      dplyr::filter(ix == jx) %>%
      dplyr::left_join(LFC_TABLE, by = c("ccle_name", "culture", "pert_mfc_id",
                                         "pert_name", "pert_time"))

    # fit curve
    a = tryCatch(dr4pl(dose = d$pert_dose, response = 2^d$LFC.cb,
                       method.init = "logistic", trend = "decreasing"),
                 error = function(e) return(NA))
    # get parameters
    param <- tryCatch(summary(a)$coefficients$Estimate, error = function(e) return(NA))
    if (!is.na(param)) {
      d %<>%
        dplyr::mutate(pred = dr4pl::MeanResponse(pert_dose, param))
      d %<>%
        dplyr::mutate(e = (2^LFC.cb - pred)^2)  # prediction residuals

      mse <- mean(d$e)
      R2 <- 1 - (sum(d$e)/(nrow(d) * var(d$LFC.cb)))

      x <- tibble(ix = jx,
                  min_dose = min(d$pert_dose),
                  max_dose = max(d$pert_dose),
                  upper_limit = param[1],
                  ec50 = param[2],
                  slope = -param[3],
                  lower_limit = param[4],
                  convergence = a$convergence) %>%
        dplyr::mutate(auc = compute_auc(lower_limit, upper_limit,
                                        ec50, slope,
                                        min(d$pert_dose), max(d$pert_dose)),
                      log2.ic50 = compute_log_ic50(lower_limit, upper_limit,
                                                   ec50, slope,
                                                   min(d$pert_dose), max(d$pert_dose)),
                      mse = mse, R2 = R2)
      DRC_cb[[jx]] <- x
    }
  }

  if (length(DRC_cb) > 0) {
    DRC_TABLE_cb <- DRC_cb %>%
      dplyr::bind_rows() %>%
      dplyr::filter(convergence) %>%
      dplyr::left_join(DRC_TABLE_cb, by = c("ix")) %>%
      dplyr::select(-ix, -convergence, -n)
  } else {
    print("Unable to fit any dose-response curves in LFC space")
    DRC_TABLE_cb <- tibble()
  }
} else {
  DRC_TABLE_cb <- tibble()
}

#---- Write to .csv ----
if(nrow(DRC_TABLE_cb) > 0)  {
  readr::write_csv(DRC_TABLE_cb, paste0(comp_dir, "/DRC_TABLE.csv"))
}

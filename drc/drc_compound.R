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
if ("LFC_cb" %in% colnames(LFC_TABLE)) {
  LFC_column <- "LFC_cb"
} else {
  LFC_column <- "LFC"
}

#---- Compute dose-response parameters ----
# table with each compound cell line combo and number of doses
compound_table <- LFC_TABLE %>%
  dplyr::select(pert_iname, pert_id, pert_dose) %>%
  dplyr::distinct() %>%
  splitstackshape::cSplit(splitCols = c("pert_dose", "pert_iname", "pert_id"),
                          sep = "|", fixed = T,
                          direction = "wide", drop = T) %>%
  dplyr::group_by(across(-c(colnames(.)[str_detect(colnames(.), pattern = "pert_dose")]))) %>%
  summarise_all(function(x) n_distinct(x, na.rm = T)) %>%
  dplyr::ungroup()

dosed_compounds <- compound_table %>%
  tidyr::pivot_longer(cols = contains("pert_iname"), names_to = c("foo", "bar", "index"), names_sep = "_", values_to = "pert_iname")
dosed_compounds$n_doses <- dosed_compounds[1, paste0("pert_dose_", dosed_compounds$index)] %>% t() %>% as.numeric()
dosed_compounds$pert_id <- dosed_compounds[1, paste0("pert_id_", dosed_compounds$index)] %>% t() %>% as.character() 
dosed_compounds %<>% 
  dplyr::select(pert_iname, pert_id, n_doses, index) %>%
  dplyr::filter(n_doses >= 4)

# distinct cell line/dose combinations
DRC_TABLE_cb <- LFC_TABLE %>%
  dplyr::distinct(pert_iname, pert_idose, pert_dose, pert_iname, pert_id, ccle_name, culture, pool_id) %>%
  splitstackshape::cSplit(splitCols = c("pert_idose", "pert_iname", "pert_id", "pert_dose"),
                          sep = "|", fixed = T,
                          direction = "wide", drop = T)
# widened version for joining
LFC_TABLE.split <- LFC_TABLE %>%
  splitstackshape::cSplit(splitCols = c("pert_idose", "pert_iname", "pert_id", "pert_dose"),
                          sep = "|", fixed = T,
                          direction = "wide", drop = F)

DRC <- list()
for (i in 1:nrow(dosed_compounds)) {
  comp <- dosed_compounds[i, ]
  dose_var <- paste0("pert_dose_", comp$index)
  df <- DRC_TABLE_cb %>%
    dplyr::group_by(across(!contains(comp$index))) %>%
    dplyr::summarise(n = n(), .groups = "drop") %>%
    dplyr::filter(n >= 4)
  sub_DRC <- list()
  for (j in 1:nrow(df)) {
    d <- df[j, ] %>% dplyr::inner_join(LFC_TABLE.split)
    
    # fit curve
    a <- tryCatch(dr4pl(dose = d[[dose_var]], response = 2^d[[LFC_column]],
                        method.init = "logistic", trend = "decreasing"),
                  error = function(e) {print(e); return(NA)})
    # get parameters
    param <- tryCatch(summary(a)$coefficients$Estimate, error = function(e) return(NA))
    
    if (!is.na(param)) {
      d$pred <- dr4pl::MeanResponse(d[[dose_var]], param)
      d$e <-  (2^d[[LFC_column]] - d$pred)^2  # prediction residuals
      
      mse <- mean(d$e)
      R2 <- 1 - (sum(d$e)/(nrow(d) * var(d[[LFC_column]])))
      
      x <- tibble(min_dose = min(d[[dose_var]]),
                  max_dose = max(d[[dose_var]]),
                  upper_limit = param[1],
                  ec50 = param[2],
                  slope = -param[3],
                  lower_limit = param[4],
                  convergence = a$convergence) %>%
        dplyr::mutate(auc = compute_auc(lower_limit, upper_limit, ec50, slope,
                                        min_dose, max_dose),
                      log2.ic50 = compute_log_ic50(lower_limit, upper_limit,
                                                   ec50, slope,
                                                   min_dose, max_dose),
                      mse = mse,
                      R2 = R2,
                      varied_iname = comp$pert_iname,
                      varied_id = comp$pert_id,
                      ccle_name = df[j,]$ccle_name,
                      culture = df[j,]$culture)
      if (ncol(df) > 4) {
        added_comp_table <- df[j, ] %>%
          tidyr::unite(col = added_compounds, starts_with("pert_iname_"), sep = "|") %>%
          tidyr::unite(col = added_idoses, starts_with("pert_idose_"), sep = "|") %>%
          tidyr::unite(col = added_doses, starts_with("pert_dose_"), sep = "|") %>%
          tidyr::unite(col = added_ids, starts_with("pert_id_"), sep = "|") %>%
          dplyr::select(-n)
        x %<>% dplyr::left_join(added_comp_table)
      }
      sub_DRC[[j]] <- x
    } else {
      sub_DRC[[j]] <- tibble()
    }
  }
  sub_DRC %<>% dplyr::bind_rows()
  DRC[[i]] <- sub_DRC
}
DRC %<>% dplyr::bind_rows()

#---- Write to .csv ----
if(nrow(DRC) > 0)  {
  readr::write_csv(DRC, paste0(out_dir, "/DRC_TABLE.csv"))
}

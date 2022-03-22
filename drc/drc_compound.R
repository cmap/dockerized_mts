# Script to go from LFC to DRC

# import necessary libraries and functions using MTS_functions.R
suppressMessages(source("./src/drc_functions.R"))

#---- Read arguments ----

parser <- ArgumentParser()
# specify our desired options
parser$add_argument("-i", "--input_dir", default="", help="Input directory with one level 4 LFC file")
parser$add_argument("-o", "--out", default="", help="Output directory")

# get command line options, if help option encountered print help and exit
args <- parser$parse_args()

lfc_dir <- args$input_dir
out_dir <- args$out

# find level 4 file and return error if none or more than one
lfc_files <- list.files(lfc_dir,pattern=("LEVEL4_LFC_.*\\.csv$"), full.names=T)
if (length(lfc_files) != 1) {
    stop(paste("There are", length(lfc_files), "LFC files in the supplied directory. Please try again with 1."),
    call. = FALSE)
} else {
  lfc_file <- lfc_files[[1]]
}

#---- Load the data ----
print("Loading data and pre-processing")
LFC_TABLE <- data.table::fread(lfc_file)
if ("LFC_cb" %in% colnames(LFC_TABLE)) {
  LFC_column <- "LFC_cb"
} else {
  LFC_column <- "LFC"
}

#---- Pre-processing ----
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

# check which compounds were run at 4 or more doses (to fit curves)
dosed_compounds <- compound_table %>%
  tidyr::pivot_longer(cols = contains("pert_iname"), names_to = c("foo", "bar", "index"), names_sep = "_", values_to = "pert_iname")
dosed_compounds$n_doses <- dosed_compounds[1, paste0("pert_dose_", dosed_compounds$index)] %>% t() %>% as.numeric()
dosed_compounds$pert_id <- dosed_compounds[1, paste0("pert_id_", dosed_compounds$index)] %>% t() %>% as.character() 
dosed_compounds %<>% 
  dplyr::select(pert_iname, pert_id, n_doses, index) %>%
  dplyr::filter(n_doses >= 4)

# if none exit
if (nrow(dosed_compounds) < 1) {
  message("Not enough dose points to fit curves for compound(s) in table")
  quit(save = "no")
}

# distinct cell line/dose combinations
DRC_TABLE_cb <- LFC_TABLE %>%
  dplyr::distinct(pert_iname, pert_time, pert_dose, pert_iname, pert_id, ccle_name, culture, pool_id, pert_plate) %>%
  splitstackshape::cSplit(splitCols = c("pert_iname", "pert_id", "pert_dose"),
                          sep = "|", fixed = T,
                          direction = "wide", drop = T, type.convert = T)
# widened version for joining
LFC_TABLE.split <- LFC_TABLE %>%
  splitstackshape::cSplit(splitCols = c("pert_iname", "pert_id", "pert_dose"),
                          sep = "|", fixed = T,
                          direction = "wide", drop = F, type.convert = T)


#---- Compute dose-response parameters ----
DRC <- list()  # stores dose response results

# for each compound run at 4+ doses
for (i in 1:nrow(dosed_compounds)) {
  comp <- dosed_compounds[i, ]
  dose_var <- paste0("pert_dose_", comp$index)  # index of compound

  # find all cell line drug combos for that compound with 4+ doses
  df <- DRC_TABLE_cb %>%
    dplyr::group_by(across(!contains(comp$index))) %>%
    dplyr::summarise(n = n(), .groups = "drop") %>%
    dplyr::filter(n >= 4)
  
  # skip if no cell lines with 4+ doses
  if (nrow(df) < 1) {
    DRC[[i]] <- tibble()
    next
  }
  
  sub_DRC <- list()  # stores dose response results
  
  # for each cell line
  for (j in 1:nrow(df)) {
    
    # get LFC data
    d <- df[j, ] %>% dplyr::inner_join(LFC_TABLE.split)
    
    # fit curve
    a <- tryCatch(dr4pl(dose = d[[dose_var]], response = 2^d[[LFC_column]],
                        init.parm = dr4pl::dr4pl_theta(theta_1 = 1, theta_4 = 0.3),
                        method.init = "logistic",
                        lowerl = c(0.99, -Inf, -Inf, 0),
                        upperl = c(1.01, Inf, Inf, 1.01)),
                  error = function(e) {print(e); return(NA)})
    
    # if it fits and doesn't converge grab robust fit
    if (!is.na(a)) {
      if (!a$convergence) {
        a <- a$dr4pl.robust 
      }
    }
    
    # get parameters
    param <- tryCatch(a$parameters, error = function(e) return(NA))
    
    # get results if fit
    if (!is.na(param)) {
      d$pred <- dr4pl::MeanResponse(a$parameters, d[[dose_var]])  # predictions
      d$e <-  (2^d[[LFC_column]] - d$pred)^2  # prediction residuals
      
      mse <- mean(d$e)
      R2 <- 1 - (sum(d$e)/(nrow(d) * var(d[[LFC_column]])))
      
      # tibble of curve parameters
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
                      culture = df[j,]$culture,
                      pert_time = df[j,]$pert_time,
                      pert_plate = df[j,]$pert_plate)
      
      # if this was a combination track other compounds added
      if (any(str_detect(colnames(df), "pert_id_"))) {
        added_comp_table <- df[j, ] %>%
          tidyr::unite(col = added_compounds, starts_with("pert_iname_"), sep = "|") %>%
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
  sub_DRC %<>% dplyr::bind_rows()  # combine results
  DRC[[i]] <- sub_DRC
}
DRC %<>% dplyr::bind_rows()  # combine results

#---- Write to .csv ----
if(nrow(DRC) > 0)  {
  readr::write_csv(DRC, paste0(out_dir, "/DRC_TABLE.csv"))
}
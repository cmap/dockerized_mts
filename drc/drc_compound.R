# Script to fit Dose-Response Curve to LFC data (using all replicates)

# import necessary libraries and functions using MTS_functions.R
suppressMessages(source("./src/drc_functions.R"))

#---- Read arguments ----
parser <- ArgumentParser()
# specify our desired options
parser$add_argument("-i", "--input_dir", default="", help="Input directory with one level 4 LFC file")
parser$add_argument("-o", "--out", default="", help="Output directory")

## For single agent screens, like MTS, the UpperLimit (UL) of fit is close to 1
## and fit is constrained to be always decreasing as we assume the compound is always toxic
## For combination screens, like CPS, the UpperLimit (UL) is b/w 0 and 1 and fit can be both increasing or decreasing.
## Increasing models antagonistic effects of the second compound.

# get command line options, if help option encountered print help and exit
args <- parser$parse_args()
lfc_dir <- args$input_dir
out_dir <- args$out

fit_type <- "single_agent" ## default screen type is MTS


# find level 4 file and return error if none or more than one
lfc_files <- list.files(lfc_dir, pattern=("*LEVEL4_LFC_.*\\.csv$"), full.names=T)
if (length(lfc_files) == 1) {
    lfc_file <- lfc_files[[1]]
} else if (length(lfc_files) == 2) {
    combat_file <- grep("COMBAT", lfc_files, value=TRUE)
    if (length(combat_file) == 1) {
        lfc_file <- combat_file[[1]]
    } else {
        stop("There are 2 LFC files, but no COMBAT file. Please try again with 1 LFC file.",
        call. = FALSE)
    }
} else {
    stop(paste("There are", length(lfc_files), "LFC files in the supplied directory. Please try again with 1."),
    call. = FALSE)
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
# if this was a combination study, we need to change fit limits accordingly
if (any(str_detect(colnames(LFC_TABLE.split), "pert_id_2"))) { ## a second pert existed.
  fit_type <- "combination"
  print("Screen type was=CPS, fit type was combination")
}
print (paste("fit type_was= ", fit_type))

#---- Compute dose-response parameters ----
DRC <- list()  # stores dose response results

# for each compound run at 4+ doses
for (i in 1:nrow(dosed_compounds)){
  print (paste("compound:", dosed_compounds[i,]))
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
    d <- df[j, ] %>% dplyr::inner_join(LFC_TABLE.split) %>% suppressMessages()
    d %<>% dplyr::filter(is.finite(.[[LFC_column]]),is.finite(.[[dose_var]]) ) # drop any infinite LFC values or undefined doses

    d$FC <- 2^d[[LFC_column]] # get fold-change values.

    # fit curve. if MTS UL is close to 1 and slope is always decreasing.
    # if CPS, UL can be further from 1 since anchor dose can be toxic and slope can increase
    if (fit_type=="single_agent"){
        fit_result.df <- get_best_fit(d, dose_var,
                                UL_low=0.8, UL_up=1.01, slope_decreasing=TRUE)
    }else if(fit_type=="combination"){
        fit_result.df <- get_best_fit(d, dose_var,
                                      UL_low=0.0, UL_up=1.01, slope_decreasing=FALSE)
    }else{ ## if screen type has not been defined before, then stop, we need to add it here.
        print("undefined fit type")
        stop("Error: undefined fit type")
    }



    # get results if fit
    if (fit_result.df$successful_fit) {

      # tibble of curve parameters
      x <- tibble(min_dose = min(d[[dose_var]]),
                  max_dose = max(d[[dose_var]]),
                  upper_limit = fit_result.df$Upper_Limit,
                  ec50 = fit_result.df$Inflection,
                  slope = -fit_result.df$Slope,                 ##### sign of slope is made negative to remain compatible with  sign convention in report generation module
                  lower_limit = fit_result.df$Lower_Limit,
                  convergence = fit_result.df$successful_fit) %>%
        dplyr::mutate(auc = compute_auc(lower_limit, upper_limit, ec50, slope,
                                        min_dose, max_dose),
                      log2.ic50 = compute_log_ic50(lower_limit, upper_limit,
                                                   ec50, slope,
                                                   min_dose, max_dose),
                      auc_riemann=fit_result.df$auc_riemann,
                      mse = fit_result.df$MSE,
                      R2 = fit_result.df$frac_var_explained,  ###  updated. old R^2 values used the variance of LFC and not FC in denominator
                      best_fit_name = fit_result.df$fit_name,
                      varied_iname = comp$pert_iname,
                      varied_id = comp$pert_id,
                      ccle_name = df[j,]$ccle_name,
                      culture = df[j,]$culture,
                      pool_id = df[j,]$pool_id,
                      pert_time = df[j,]$pert_time,
                      pert_plate = df[j,]$pert_plate,
                      fit_type= fit_type)

      # if this was a combination track other compounds added
      if (any(str_detect(colnames(df), "pert_id_"))) {
        added_comp_table <- df[j, ] %>%
          tidyr::unite(col = added_compounds, starts_with("pert_iname_"), sep = "|") %>%
          tidyr::unite(col = added_doses, starts_with("pert_dose_"), sep = "|") %>%
          tidyr::unite(col = added_ids, starts_with("pert_id_"), sep = "|") %>%
          dplyr::select(-n)
        x %<>% dplyr::left_join(added_comp_table)%>% suppressMessages()
      }
      sub_DRC[[j]] <- x
    } else { # fit is unsuccessful and so all we can really provide is the riemann auc but we add the other columns as well for completeness
      x <- tibble(min_dose = min(d[[dose_var]]),
                  max_dose = max(d[[dose_var]]),
                  upper_limit = as.numeric(NA),
                  ec50 = as.numeric(NA),
                  slope = as.numeric(NA),
                  lower_limit =as.numeric(NA),
                  convergence = fit_result.df$successful_fit) %>%
        dplyr::mutate(auc = as.numeric(NA),
                      log2.ic50 = as.numeric(NA),
                      auc_riemann=fit_result.df$auc_riemann,
                      mse = as.numeric(NA),
                      R2 = as.numeric(NA),  
                      best_fit_name = NA,
                      varied_iname = comp$pert_iname,
                      varied_id = comp$pert_id,
                      ccle_name = df[j,]$ccle_name,
                      culture = df[j,]$culture,
                      pool_id = df[j,]$pool_id,
                      pert_time = df[j,]$pert_time,
                      pert_plate = df[j,]$pert_plate,
                      fit_type= fit_type)
      # if this was a combination track other compounds added
      if (any(str_detect(colnames(df), "pert_id_"))) {
        added_comp_table <- df[j, ] %>%
          tidyr::unite(col = added_compounds, starts_with("pert_iname_"), sep = "|") %>%
          tidyr::unite(col = added_doses, starts_with("pert_dose_"), sep = "|") %>%
          tidyr::unite(col = added_ids, starts_with("pert_id_"), sep = "|") %>%
          dplyr::select(-n)
        x %<>% dplyr::left_join(added_comp_table)%>% suppressMessages()
      }
      sub_DRC[[j]] <- x
      # sub_DRC[[j]] <- tibble(min_dose = min(d[[dose_var]]),######
      #                        max_dose = max(d[[dose_var]]),
      #                        upper_limit = as.numeric(NA),
      #                        ec50 = as.numeric(NA),
      #                        slope = as.numeric(NA),                 ##### sign of slope is made negative to remain compatible with  sign convention in report generation module
      #                        lower_limit = as.numeric(NA),
      #                        convergence = FALSE) %>%
      #     dplyr::mutate(auc = as.numeric(NA),
      #                   log2.ic50 = as.numeric(NA),
      #                   auc_riemann=fit_result.df$auc_riemann,
      #                   mse = ifelse("mse" %in% colnames(fit_result.df), fit_result.df$MSE, as.numeric(NA) ),
      #                   R2 = ifelse("frac_var_explained" %in% colnames(fit_result.df), fit_result.df$frac_var_explained, as.numeric(NA) ),  ###  updated. old R^2 values used the variance of LFC and not FC in denominator
      #                   best_fit_name = NA,
      #                   varied_iname = comp$pert_iname,
      #                   varied_id = comp$pert_id,
      #                   ccle_name = df[j,]$ccle_name,
      #                   culture = df[j,]$culture,
      #                   pool_id = df[j,]$pool_id,
      #                   pert_time = df[j,]$pert_time,
      #                   pert_plate = df[j,]$pert_plate)
    }
    if (is.na(fit_result.df$successful_fit)){
      x <- tibble(min_dose = min(d[[dose_var]]),######
                             max_dose = max(d[[dose_var]]),
                             upper_limit = as.numeric(NA),
                             ec50 = as.numeric(NA),
                             slope = as.numeric(NA),                 ##### sign of slope is made negative to remain compatible with  sign convention in report generation module
                             lower_limit = as.numeric(NA),
                             convergence = FALSE) %>%
          dplyr::mutate(auc = as.numeric(NA),
                        log2.ic50 = as.numeric(NA),
                        auc_riemann=as.numeric(NA),
                        mse = as.numeric(NA),
                        R2 = as.numeric(NA),  ###  updated. old R^2 values used the variance of LFC and not FC in denominator
                        best_fit_name = NA,
                        varied_iname = comp$pert_iname,
                        varied_id = comp$pert_id,
                        ccle_name = df[j,]$ccle_name,
                        culture = df[j,]$culture,
                        pool_id = df[j,]$pool_id,
                        pert_time = df[j,]$pert_time,
                        pert_plate = df[j,]$pert_plate,
                        fit_type= fit_type)
      if (any(str_detect(colnames(df), "pert_id_"))) {
        added_comp_table <- df[j, ] %>%
          tidyr::unite(col = added_compounds, starts_with("pert_iname_"), sep = "|") %>%
          tidyr::unite(col = added_doses, starts_with("pert_dose_"), sep = "|") %>%
          tidyr::unite(col = added_ids, starts_with("pert_id_"), sep = "|") %>%
          dplyr::select(-n)
        x %<>% dplyr::left_join(added_comp_table)%>% suppressMessages()
      }
      sub_DRC[[j]] <- x
    }

  }

  sub_DRC %<>% dplyr::bind_rows()  # combine results
  DRC[[i]] <- sub_DRC
}
DRC %<>% dplyr::bind_rows()  # combine results


# #---- Write to .csv ----
if(nrow(DRC) > 0)  {
  write.csv(DRC, paste0(out_dir, "/DRC_TABLE.csv"), row.names=FALSE)
}
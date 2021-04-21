# Script to go from LFC to DRC

# import necessary libraries and functions using MTS_functions.R
suppressMessages(source("./src/MTS_functions.R"))

#---- Read arguments ----
script_args <- commandArgs(trailingOnly = TRUE)
if (length(script_args) != 5) {
  stop("Please supply necessary arguments",
       call. = FALSE)
}
base_dir <- script_args[1]
out_dir <- script_args[2]
project_name <- script_args[3]
compound <- script_args[4]
calc_gr <- as.numeric(script_args[5])

safe_name <- stringr::str_replace_all(project_name, "[[:punct:]\\s]+", "_")
write_name <- stringr::str_replace_all(compound, "[[:punct:]\\s]+", "-")

project_dir <- paste(out_dir, safe_name, sep = fixed("/"))
comp_dir <- paste(project_dir, write_name, sep = fixed("/"))
if (!dir.exists(comp_dir)) {dir.create(comp_dir, recursive = T)}

#---- Load the data ----
print("Loading data and pre-processing")
LFC_TABLE <- data.table::fread(paste0(base_dir, "/LFC_TABLE.csv")) %>%
  dplyr::filter(pert_name == compound, project_id == project_name)
if (calc_gr) {
  GR_TABLE <- data.table::fread(paste0(base_dir, "/GR_TABLE.csv")) %>%
    dplyr::filter(pert_name == compound, project_id == project_name)
}

#---- Compute dose-response parameters ----
# table with each compound cell line combo and number of doses
DRC_TABLE_cb <- LFC_TABLE %>%
  dplyr::filter(pert_type == "trt_cp") %>%
  dplyr::distinct(ccle_name, culture, pert_mfc_id, pert_name, pert_dose, pert_time) %>%
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

# GROWTH RATE DOSE-RESPONSE
if (calc_gr) {
  print("Fitting growth dose-response curves")
  DRC_TABLE_growth <- GR_TABLE %>%
    dplyr::distinct(ccle_name, culture, pert_mfc_id, pert_name, pert_dose, pert_time) %>%
    dplyr::count(ccle_name, culture, pert_mfc_id, pert_name, pert_time) %>%
    dplyr::filter(n > 3)
  
  if (nrow(DRC_TABLE_growth > 0)) {
    DRC_TABLE_growth %<>% dplyr::mutate(ix = 1:n())
    DRC_gr <- list()
    
    for (jx in 1:nrow(DRC_TABLE_growth)) {
      d = DRC_TABLE_growth %>%
        dplyr::filter(ix == jx) %>%
        dplyr::left_join(GR_TABLE, by = c("ccle_name", "culture", "pert_mfc_id",
                                          "pert_name", "pert_time"))
      
      a = tryCatch(dr4pl(dose = d$pert_dose, response = d$GR,
                         method.init = "logistic", trend = "decreasing"),
                   error = function(e) return(NA))
      param <- tryCatch(summary(a)$coefficients$Estimate, error = function(e) return(NA))
      if (!is.na(param)) {
        d %<>%
          dplyr::mutate(pred = dr4pl::MeanResponse(pert_dose, param))
        d %<>%
          dplyr::mutate(e = (GR - pred)^2)  # prediction residuals
        
        mse <- mean(d$e)
        R2 <- 1 - (sum(d$e)/(nrow(d) * var(d$GR)))
        
        x <- tibble(ix = jx,
                    min_dose = min(d$pert_dose),
                    max_dose = max(d$pert_dose),
                    upper_limit = param[1],
                    ec50 = param[2],
                    slope = -param[3],
                    lower_limit = param[4],
                    convergence = a$convergence) %>%
          dplyr::mutate(aoc = compute_aoc(lower_limit,
                                          upper_limit,
                                          ec50,
                                          slope,
                                          min(d$pert_dose),
                                          max(d$pert_dose)),
                        log2.gr50 = compute_log_gr50(lower_limit,
                                                     upper_limit,
                                                     ec50,
                                                     slope,
                                                     min(d$pert_dose),
                                                     max(d$pert_dose)),
                        mse = mse,
                        R2 = R2)
        DRC_gr[[jx]] <- x
      }
    }
    
    if (length(DRC_gr) > 0) {
      DRC_TABLE_growth <- DRC_gr %>%
        dplyr::bind_rows() %>%
        dplyr::filter(convergence) %>%
        dplyr::left_join(DRC_TABLE_growth, by = c("ix")) %>%
        dplyr::select(-ix, -convergence, -n)
    } else {
      print("Unable to fit any dose-response curves in GR space")
      DRC_TABLE_growth <- tibble()
    }
  } else {
    DRC_TABLE_growth <- tibble()
  }
}

#---- Write to .csv ----
if(nrow(DRC_TABLE_cb) > 0)  {
  readr::write_csv(DRC_TABLE_cb, paste0(comp_dir, "/DRC_TABLE.csv"))
}

# GR data if it exists
if(calc_gr) {
  if (nrow(DRC_TABLE_growth)) {
    readr::write_csv(DRC_TABLE_growth, paste0(comp_dir, "/DRC_TABLE_GR.csv")) 
  }
}


#---- Generate DRC plots ----
if(nrow(DRC_TABLE_cb) > 0) {
  print("Generating plot PDFs")
  # dose response data
  DRC_TABLE_cb %<>% dplyr::arrange(auc)
  
  # create .pdf
  pdf(paste0(comp_dir, "/", toupper(write_name), "_DRCfigures.pdf"))
  
  # loop through each cell line treated by compound and plot DRC
  conditions <- DRC_TABLE_cb %>% dplyr::distinct(ccle_name, culture, pert_time)
  for(j in 1:nrow(conditions)) {
    condition <- conditions[j,]
    assay_time <- condition$pert_time
    cell_line <- condition$ccle_name
    culture <- condition$culture
    
    d <- DRC_TABLE_cb %>% dplyr::inner_join(condition,
                                            by = c("ccle_name", "culture", "pert_time"))
    d_cult_line <- LFC_TABLE %>% dplyr::inner_join(condition,
                                                   by = c("ccle_name", "culture", "pert_time"))
    
    # DRC curve function
    f1 = function(x) {
      d$lower_limit + (d$upper_limit - d$lower_limit)/
        (1 + (2^x/d$ec50)^d$slope)
    }
    
    # sequence for plotting curve
    xx = seq(log2(d$min_dose), log2(d$max_dose),
             length.out = 1000)
    
    # plot individual data points and DRC fit line
    p = d_cult_line %>%
      ggplot() +
      geom_point(aes(x = log2(pert_dose),
                     color = prism_replicate, y = 2^LFC.cb)) +
      geom_line(data = tibble(x = xx, y = f1(xx)),
                aes(x = x, y = y, group = 1),  lwd =1) +
      ylim(0,2) + theme_bw() +
      labs(x = 'log2(Dose) (uM)', y = 'Viability', color = "",
           title = paste0(compound, "-", assay_time, "\n", cell_line,' - ', culture,
                          "\nAUC:", round(d$auc, 2),
                          " - IC50:", round(2^d$log2.ic50, 2)))
    # outputs to .pdf
    print(p)
  }
  # closes .pdf
  invisible(dev.off())
}

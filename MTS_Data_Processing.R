# Script to run the initial processing step of the MTS pipeline.
# Input is the path to a .csv of logMFI values

# import necessary libraries and functions using MTS_functions.R
suppressMessages(source("./src/MTS_functions.R"))

#---- Read arguments ----
script_args <- commandArgs(trailingOnly = TRUE)
if (length(script_args) != 5) {
  stop("Please supply path to data, output directory, project name, assay and project key directory (where project_key.csv is located)",
       call. = FALSE)
}
base_dir <- script_args[1]
out_dir <- script_args[2]
project_name <- script_args[3]
assay <- script_args[4]
project_key_dir <- script_args[5]


print(base_dir)
print(out_dir)
print(project_name)
print(assay)
print(project_key_dir)

safe_name <- stringr::str_replace_all(project_name, "[[:punct:]\\s]+", "_")
project_dir <- paste(out_dir, safe_name, sep = fixed("/"))
if (!dir.exists(project_dir)) {dir.create(project_dir, recursive = T)}

# paths to data (make sure directory of data has these files)
path_key <- list.files(project_key_dir, pattern = "*project_key.csv", full.names = T)
path_data <- list.files(base_dir,
                        pattern = paste0("*", assay, "*_LEVEL2_MFI*"),
                        full.names = T)
path_cell_info <- list.files(base_dir,
                             pattern = paste0("*", assay, "*_cell_info*"),
                             full.names = T)
path_inst_info <- list.files(base_dir,
                             pattern = paste0("*", assay, "*_inst_info"),
                             full.names = T)

print(path_key)
print(path_data)
print(path_cell_info)
print(path_inst_info)
#---- Load the data ----

# data table linking drugs to projects (collaborators)
key_table <- data.table::fread(path_key)

# read in logMFI data
raw_matrix <- read_hdf5(path_data)
rownames(raw_matrix) <- paste0(rownames(raw_matrix), "_", assay)

# read in cell line info
cell_info <- data.table::fread(path_cell_info) %>%
  dplyr::distinct(rid, ccle_name, pool_id) %>%
  dplyr::mutate(culture = assay) %>%
  dplyr::mutate(rid = paste0(rid, "_", assay)) %>%
  dplyr::mutate(pool_id = ifelse(pool_id == "" | pool_id == -666,
                                 "CTLBC", pool_id))

# combine with CMap assay info
inst_info <- data.table::fread(path_inst_info) %>%
  dplyr::filter(!str_detect(pert_plate, "BASE"), !is_well_failure) %>%
  make_long_map(.)
base_day <- data.table::fread(path_inst_info) %>%
  dplyr::filter(str_detect(prism_replicate, "BASE"), !is_well_failure) %>%
  dplyr::rename(pert_name = pert_iname)  %>%
  dplyr::select(colnames(inst_info))
inst_info %<>% dplyr::bind_rows(base_day)

# ensure unique profile IDs (this may cause problems for combo-perturbations)
raw_matrix <- raw_matrix[, inst_info$profile_id %>% unique()]

# melt matrix into data tables and join with inst and cell info
master_logMFI <- log2(raw_matrix) %>%
  reshape2::melt(varnames = c("rid", "profile_id"), value.name = "logMFI") %>%
  dplyr::inner_join(cell_info) %>%
  dplyr::inner_join(inst_info) %>%
  dplyr::select(profile_id, rid, ccle_name, pool_id, culture, prism_replicate, pert_time, 
                pert_type, pert_dose, pert_idose, pert_mfc_id, pert_name, pert_well,
                logMFI)

# change validation (.es) to treatment for processing
master_logMFI$pert_type[which(master_logMFI$pert_type == "trt_poscon.es")] <-
  "trt_cp"
master_logMFI$pert_type[which(master_logMFI$pert_type == "trt_cpd")] <-
  "trt_cp"

# filter to just project and controls
project_data <- key_table %>%
  dplyr::filter(project_id == project_name) %>%
  dplyr::distinct(pert_name)

compounds_logMFI <- master_logMFI %>%
  dplyr::filter(pert_name %in% project_data$pert_name)

controls_logMFI <- master_logMFI %>%
  dplyr::filter(pert_type %in% c("ctl_vehicle", "trt_poscon"),
                prism_replicate %in% unique(compounds_logMFI$prism_replicate) |
                  str_detect(prism_replicate, "BASE"))

varied_compounds <- compounds_logMFI %>%
  dplyr::distinct(pert_name, pert_idose) %>%
  dplyr::group_by(pert_name) %>%
  dplyr::summarize(n = n()) %>%
  dplyr::filter(n > 1) %>%
  dplyr::ungroup()

compounds_logMFI %<>%
  dplyr::group_by(profile_id, rid, ccle_name, pool_id, culture, prism_replicate,
                  pert_type, pert_well, pert_time, logMFI) %>%
  dplyr::summarize(pert_dose = ifelse(any(pert_name %in% varied_compounds$pert_name),
                                      pert_dose[pert_name %in% varied_compounds$pert_name],
                                      pert_dose),
                   pert_idose = ifelse(any(pert_name %in% varied_compounds$pert_name),
                                       pert_idose[pert_name %in% varied_compounds$pert_name],
                                       pert_idose),
                   pert_mfc_id = ifelse(any(pert_name %in% varied_compounds$pert_name),
                                        pert_mfc_id[pert_name %in% varied_compounds$pert_name],
                                        pert_mfc_id),
                   pert_name = paste(unique(pert_name), collapse = "_")) %>%
  dplyr::ungroup()

master_logMFI <- dplyr::bind_rows(compounds_logMFI, controls_logMFI)

base_day_num <- as.numeric(str_sub(unique(base_day$pert_time), 1, -2))/24

# create barcode tables
barcodes <- master_logMFI %>%
  dplyr::filter(pool_id == "CTLBC")

# filter base plates
logMFI_base <- master_logMFI %>%
  dplyr::filter(str_detect(prism_replicate, "BASE"))
master_logMFI %<>%
  dplyr::filter(!str_detect(prism_replicate, "BASE"))

#---- Normalize ----

# compute control barcode median of medians for normalization
logMFI_control_medians <- control_medians(master_logMFI)

# fit curve to controls and predict test conditions
logMFI_normalized <- normalize(logMFI_control_medians, barcodes)

# if there is an early measurement
if(nrow(logMFI_base) > 0) {
  # generate reference profile to normalize base data
  logMFI_profile <- logMFI_normalized %>%
    dplyr::filter(rid %in% barcodes$rid) %>%
    dplyr::group_by(rid) %>%
    dplyr::mutate(rLMFI = mean(rLMFI)) %>%
    dplyr::ungroup() %>%
    dplyr::distinct(rid, rLMFI)
  
  base_normalized <- logMFI_base %>%
    dplyr::left_join(logMFI_profile) %>%
    normalize(., barcodes)
} else if(file.exists(paste0(dirname(data_path), "/external_day0.csv"))) {
  base_normalized <- data.table::fread(paste0(dirname(data_path),
                                              "/external_day0.csv")) %>%
    dplyr::filter(culture == "PR300")
} else {
  base_normalized <- tibble()
}

# join with other info (LMFI is normalized, logMFI is not)
logMFI_normalized %<>%
  dplyr::left_join(master_logMFI) %>%
  dplyr::select(-logMFI)

#---- Calculate QC metrics ----

# calculate SSMD and NNMD
SSMD_TABLE <- calc_ssmd(logMFI_normalized %>%
                          dplyr::filter(pool_id != "CTLBC"))
# calculate error rate of normalized table (based on threshold classifier)
error_table <- logMFI_normalized %>%
  dplyr::filter(pert_type %in% c("ctl_vehicle", "trt_poscon"),
                is.finite(LMFI), pool_id != "CTLBC") %>%
  dplyr::group_by(rid, ccle_name, prism_replicate) %>%
  dplyr::summarize(error_rate =
                     min(PRROC::roc.curve(scores.class0 = LMFI,
                                          weights.class0 = pert_type == "ctl_vehicle",
                                          curve = TRUE)$curve[,1] + 1 -
                           PRROC::roc.curve(scores.class0 = LMFI,
                                            weights.class0 = pert_type == "ctl_vehicle",
                                            curve = TRUE )$curve[,2])/2)
# join with SSMD table
SSMD_TABLE %<>% 
  dplyr::left_join(error_table) %>%
  dplyr::mutate(pass = error_rate <= 0.05,
                compound_plate = stringr::word(prism_replicate, 1,
                                                sep = stringr::fixed("_")))

#---- Compute log-fold changes ----

LFC_TABLE <- logMFI_normalized %>%
  # join with SSMD (to filter bad lines)
  dplyr::inner_join(SSMD_TABLE %>%
                      dplyr::distinct(ccle_name, prism_replicate, culture, pass)) %>%
  dplyr::filter(pass) %>%
  dplyr::group_by(prism_replicate, ccle_name, culture) %>%
  # calculate LFC (LMFI - median(LMFIcontrol))
  dplyr::mutate(LFC = LMFI - median(LMFI[pert_type == "ctl_vehicle"])) %>%
  dplyr::distinct(pert_mfc_id, pert_name, prism_replicate, culture, rid, LFC,
                  pert_type, ccle_name, pert_dose, pert_well, pool_id, pert_time, 
                  profile_id, pert_idose) %>%
  dplyr::ungroup()

#---- Correct for pool effects ----

LFC_TABLE %<>%
  dplyr::filter(pert_type == "trt_cp") %>%
  dplyr::mutate(compound_plate = stringr::word(prism_replicate, 1,
                                               sep = stringr::fixed("_"))) %>%
  tidyr::unite(col = "condition", pert_name, pert_dose, compound_plate, pert_time,
               sep = "::", remove = FALSE) %>%
  split(.$condition) %>%
  purrr::map_dfr(~dplyr::mutate(.x, LFC.cb = apply_combat(.))) %>%
  dplyr::select(-condition)

#---- Compute growth rates ----

# control (base) and DMSO
CONTROL_GR <- tryCatch(expr = {base_normalized %>%
    dplyr::group_by(pert_time, ccle_name, rid, pool_id, culture) %>%  # no compound to group by
    dplyr::summarize(mLMFI.c = median(LMFI),
                     n.c = n(),
                     var.c = (mad(LMFI)^2/n.c) * pi/2) %>%  # n = replicates (~300)
    dplyr::select(-n.c) %>%
    dplyr::ungroup() %>%
    dplyr::rename(pert_base_time = pert_time) %>%
    # join with DMSO
    dplyr::inner_join(logMFI_normalized %>%
                        dplyr::filter(pert_type == "ctl_vehicle") %>%
                        dplyr::mutate(assay_length = as.numeric(str_sub(pert_time, 1, -2))/24) %>%
                        dplyr::group_by(ccle_name, rid, pool_id, culture, pert_time, assay_length) %>%
                        dplyr::summarize(mLMFI.d = median(LMFI),
                                         n.d = n(),
                                         var.d = (mad(LMFI)^2/n.d) * pi/2) %>%
                        dplyr::select(-n.d))
}, error = function(e) {
  return(NA)
})
# treatment
GR_TABLE <- tryCatch(expr = {logMFI_normalized %>%
    dplyr::mutate(assay_length = as.numeric(str_sub(pert_time, 1, -2))/24) %>%
    # now group by compound
    dplyr::group_by(pert_mfc_id, pert_type, pert_name, pert_dose, pert_idose,
                    ccle_name, rid, pool_id, culture, pert_time, assay_length) %>%
    dplyr::summarize(mLMFI.t = median(LMFI),
                     n.t = n(),
                     var.t = (mad(LMFI)^2/n.t) * pi/2) %>%  # n.t = 3 (replicates)
    dplyr::select(-n.t) %>%
    dplyr::inner_join(CONTROL_GR) %>%
    dplyr::ungroup()
}, error = function(e) {
  return(tibble())
})

# combined
GR_TABLE <- tryCatch(expr = {GR_TABLE %>%
    # calc control change (DMSO - base)/(t - base day),
    # treatment change (treatment - DMSO)/t - control,
    # use to calc Z (treatment/control) and GR (2^Z - 1)
    dplyr::mutate(control_lfc = (mLMFI.d - mLMFI.c)/(assay_length - base_day_num),
                  treatment_control_lfc = (mLMFI.t - mLMFI.d)/(assay_length),
                  treatment_lfc = treatment_control_lfc + control_lfc,
                  Z = treatment_lfc/control_lfc,
                  var.treatment = (var.t/assay_length^2) + (var.d/(assay_length - base_day_num)^2) +
                    (var.c*(1/(assay_length-base_day_num) - 1/assay_length)^2),
                  var.control = (var.c + var.d)/(assay_length - base_day_num)^2,
                  GR = (2^Z) - 1) %>%
    dplyr::distinct(pert_mfc_id, pert_type, pert_name, pert_dose, pert_idose,
                    rid, ccle_name, culture, pool_id, pert_time, assay_length,
                    control_lfc, treatment_lfc, Z, var.treatment, var.control, GR) %>%
    dplyr::mutate(base_day = base_day_num)
}, error = function(e) {
  return(tibble())
})

#---- Compute dose-response parameters ----

# table with each compound cell line combo and number of doses
DRC_TABLE_cb <- LFC_TABLE %>%
  dplyr::filter(pert_type == "trt_cp") %>%
  dplyr::distinct(ccle_name, culture, pert_mfc_id, pert_name, pert_dose, pert_time) %>%
  dplyr::count(ccle_name, culture, pert_mfc_id, pert_name, pert_time) %>%
  dplyr::filter(n > 4) %>%  # only fit curves with 4+ doses
  dplyr::mutate(ix = 1:n())

DRC_cb <- list()  # empty tibble to track results

# loop through compound cell line combos fitting curves
for(jx in 1:nrow(DRC_TABLE_cb)) {
  d = DRC_TABLE_cb %>%
    dplyr::filter(ix == jx) %>%
    dplyr::left_join(LFC_TABLE)
  
  # fit curve
  a = tryCatch(dr4pl(dose = d$pert_dose,
                     response = 2^d$LFC.cb,
                     method.init = "logistic",
                     trend = "decreasing"),
               error = function(e) NA)
  # get parameters
  param <- tryCatch(summary(a)$coefficients$Estimate, error = function(e) NA)
  if(!is.na(param)) {
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
      dplyr::mutate(auc = compute_auc(lower_limit,
                                      upper_limit,
                                      ec50,
                                      slope,
                                      min(d$pert_dose),
                                      max(d$pert_dose)),
                    log2.ic50 = compute_log_ic50(lower_limit,
                                                 upper_limit,
                                                 ec50,
                                                 slope,
                                                 min(d$pert_dose),
                                                 max(d$pert_dose)),
                    mse = mse,
                    R2 = R2)
    DRC_cb[[jx]] <- x
  }
}

if(length(DRC_cb) > 0) {
  DRC_TABLE_cb <- DRC_cb %>%
    dplyr::bind_rows() %>%
    dplyr::filter(convergence) %>%
    dplyr::left_join(DRC_TABLE_cb) %>%
    dplyr::select(-ix, -convergence, -n)
} else {
  print("Unable to fit any dose-response curves in LFC space")
  DRC_TABLE_cb <- NA
}

# GROWTH RATE DOSE-RESPONSE
if(nrow(GR_TABLE) > 0) {
  DRC_TABLE_growth <- GR_TABLE %>%
    dplyr::distinct(ccle_name, culture, pert_mfc_id, pert_name, pert_dose, pert_time) %>%
    dplyr::count(ccle_name, culture, pert_mfc_id, pert_name, pert_time) %>%
    dplyr::filter(n > 4) %>%
    dplyr::mutate(ix = 1:n())
  
  DRC_gr <- list()
  
  for(jx in 1:nrow(DRC_TABLE_growth)) {
    d = DRC_TABLE_growth %>%
      dplyr::filter(ix == jx) %>%
      dplyr::left_join(GR_TABLE)
    
    a = tryCatch(dr4pl(dose = d$pert_dose,
                       response = d$GR,
                       method.init = "logistic",
                       trend = "decreasing"),
                 error = function(e) NA)
    param <- tryCatch(summary(a)$coefficients$Estimate, error = function(e) NA)
    if(!is.na(param)) {
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
  
  if(length(DRC_gr) > 0) {
    DRC_TABLE_growth <- DRC_gr %>%
      dplyr::bind_rows() %>%
      dplyr::filter(convergence) %>%
      dplyr::left_join(DRC_TABLE_growth) %>%
      dplyr::select(-ix, -convergence, -n)
  } else {
    print("unable to fit any dose-response curves in GR space")
    DRC_TABLE_growth <- NA
  }
}

#---- Make collapsed LFC table ----

LFC_COLLAPSED_TABLE <- LFC_TABLE %>%
  dplyr::mutate(compound_plate = stringr::word(prism_replicate, 1,
                                               sep = stringr::fixed("_"))) %>%
  dplyr::group_by(ccle_name, culture, pool_id, pert_name, pert_mfc_id,
                  pert_dose, pert_idose, compound_plate, pert_time) %>%
  # LFC and LFC.cb values will be medains across replicates
  dplyr::summarize(LFC = median(LFC, na.rm = TRUE),
                   LFC.cb = median(LFC.cb, na.rm = TRUE))


#---- Write to .csv ----
# raw logMFI
readr::write_csv(master_logMFI, paste0(project_dir, "/logMFI.csv"))

# normalized logMFI
logMFI_normalized %>%
  dplyr::select(-rLMFI) %>%
  readr::write_csv(., paste0(project_dir, "/logMFI_NORMALIZED.csv"))

# QC table
readr::write_csv(SSMD_TABLE, paste0(project_dir, "/SSMD_TABLE.csv"))

# compound data (DRC, LFC)
compounds <- dplyr::distinct(LFC_TABLE, pert_name, pert_mfc_id)
for(i in 1:nrow(compounds)) {
  id <- compounds[[i, "pert_mfc_id"]]  # Broad ID (unique)
  name <- compounds[[i, "pert_name"]]  # name (human readable)
  write_name <- stringr::str_replace_all(name, "[[:punct:]\\s]+", "-")
  
  # output directory
  path <- paste0(project_dir, "/", write_name)
  if(!dir.exists(path)) {
    dir.create(path)
  }
  
  lfc <- dplyr::filter(LFC_TABLE, pert_name == name)
  drc <- dplyr::filter(DRC_TABLE_cb, pert_name == name)
  lfc_coll <- dplyr::filter(LFC_COLLAPSED_TABLE, pert_name == name)
  
  readr::write_csv(lfc, paste0(path, "/LFC_TABLE.csv"))
  readr::write_csv(lfc_coll, paste0(path, "/LFC_COLLAPSED_TABLE.csv"))
  if(nrow(drc) > 0)  {
    readr::write_csv(drc, paste0(path, "/DRC_TABLE.csv"))
  }
  
  # GR data if it exists
  if(nrow(GR_TABLE) > 0) {
    gr <- dplyr::filter(GR_TABLE, pert_mfc_id == id)
    readr::write_csv(gr, paste0(path, "/GR_TABLE.csv"))
    if(!is.na(DRC_TABLE_growth)) {
      drc_gr <- dplyr::filter(DRC_TABLE_growth, pert_mfc_id == id)
      readr::write_csv(drc_gr, paste0(path, "/DRC_TABLE_GR.csv")) 
    }
  }
}

#---- Generate DRC plots ----
# generate a .pdf of graphs for each compound
for(i in 1:nrow(compounds)) {
  id <- compounds[[i, "pert_mfc_id"]]
  name <- compounds[[i, "pert_name"]]
  write_name <- stringr::str_replace_all(name, "[[:punct:]\\s]+", "-")
  
  # filter to just see that compound
  compound_DRC <- DRC_TABLE_cb %>%
    dplyr::filter(pert_name == name)
  
  if(nrow(compound_DRC) < 1) {
    next
  }
  
  compound_DRC %<>%
    dplyr::arrange(auc)
  
  # tracks LFC info
  compound_LFC <- LFC_TABLE %>%
    dplyr::filter(pert_name == name)
  
  # create .pdf
  pdf(paste0(project_dir, "/", write_name, "/",
             toupper(write_name), "_DRCfigures.pdf"))
  
  # loop through each cell line treated by compound and plot DRC
  conditions <- compound_DRC %>% dplyr::distinct(ccle_name, culture, pert_time)
  for(j in 1:nrow(conditions)) {
    condition <- conditions[i,]
    assay_time <- condition$pert_time
    cell_line <- condition$ccle_name
    culture <- condition$culture
    
    d <- compound_DRC %>%
      dplyr::inner_join(condition)
    d_cult_line <- compound_LFC %>%
      dplyr::inner_join(condition)
    
    # DRC curve function
    f1 = function(x) {
      d$lower_limit + (d$upper_limit - d$lower_limit)/
        (1 + (2^x/d$ec50)^d$slope)
    }
    # sequence for plotting curve
    xx = seq(min(log2(d_cult_line$pert_dose)),
             max(log2(d_cult_line$pert_dose)),
             length.out = 1000)
    # plot individual data points and DRC fit line
    p = d_cult_line %>%
      ggplot() +
      geom_point(aes(x = log2(pert_dose),
                     color = prism_replicate, y = 2^LFC.cb)) +
      geom_line(data = tibble(x = xx, y = f1(xx)),
                aes(x = x, y = y, group = 1),  lwd =1 ) +
      ylim(0,2) + theme_bw() +
      labs(x = 'log2(Dose) (uM)', y = 'Viability', color = "",
           title = paste0(name, "-", assay_time, "\n", cell_line,' - ', culture,
                          "\nAUC:", round(d$auc, 2),
                          " - IC50:", round(2^d$log2.ic50, 2)))
    # outputs to .pdf
    print(p)
  }
  # closes .pdf
  dev.off()
}

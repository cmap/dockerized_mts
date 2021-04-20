# Script to go from normalized logMFI values to LFC

# import necessary libraries and functions using MTS_functions.R
suppressMessages(source("./src/MTS_functions.R"))

#---- Read arguments ----
script_args <- commandArgs(trailingOnly = TRUE)
if (length(script_args) != 3) {
  stop("Please supply necessary arguments",
       call. = FALSE)
}
base_dir <- script_args[1]
out_dir <- script_args[2]
calc_gr <- as.numeric(script_args[3])

if (!dir.exists(out_dir)) {dir.create(out_dir, recursive = T)}

#---- Load the data ----
print("Loading data and pre-processing")
logMFI_normalized <- data.table::fread(paste0(base_dir, "/logMFI_NORMALIZED.csv"))

# split into base and final reading
base_normalized <- logMFI_normalized %>%
  dplyr::filter(str_detect(prism_replicate, "BASE"))
logMFI_normalized %<>%
  dplyr::filter(str_detect(prism_replicate, "BASE", negate = T))
SSMD_TABLE <- data.table::fread(paste0(base_dir, "/SSMD_TABLE.csv")) %>%
  dplyr::filter(prism_replicate %in% plates$prism_replicate)

plates <- distinct(logMFI_normalized, prism_replicate) %>%
  dplyr::mutate(compound_plate = stringr::word(prism_replicate, 1,
                                               sep = fixed("_")))

#---- Compute log-fold changes ----
print("Calculating log-fold changes")
LFC_TABLE <- logMFI_normalized
# if QC able to be applied
if (!all(is.na(SSMD_TABLE$pass))) {
  LFC_TABLE %<>%
    # join with SSMD (to filter bad lines)
    dplyr::inner_join(SSMD_TABLE %>%
                        dplyr::distinct(ccle_name, prism_replicate, culture, pass),
                      by = c("prism_replicate", "ccle_name", "culture")) %>%
    dplyr::filter(pass)
} else {
  print("Problem with QC metrics: including all lines")
}
LFC_TABLE %<>%
  dplyr::group_by(prism_replicate, ccle_name, culture, pert_time) %>%
  dplyr::mutate(LFC = LMFI - median(LMFI[pert_type == "ctl_vehicle"])) %>%
  dplyr::distinct(pert_mfc_id, pert_name, prism_replicate, culture, rid, LFC,
                  pert_type, ccle_name, pert_dose, pert_well, pool_id, pert_time,
                  profile_id, pert_idose, project_id) %>%
  dplyr::ungroup()

#---- Correct for pool effects ----
print("ComBat correcting")
LFC_TABLE %<>%
  dplyr::filter(pert_type != "ctl_vehicle") %>%
  dplyr::left_join(plates, by = c("prism_replicate")) %>%
  tidyr::unite(col = "condition", pert_name, pert_dose, compound_plate, pert_time, project_id,
               sep = "::", remove = FALSE) %>%
  split(.$condition) %>%
  purrr::map_dfr(~dplyr::mutate(.x, LFC.cb = apply_combat(.))) %>%
  dplyr::select(-condition)

#---- Make collapsed LFC table ----
LFC_COLLAPSED_TABLE <- LFC_TABLE %>%
  dplyr::group_by(ccle_name, culture, pool_id, pert_name, pert_mfc_id,
                  pert_dose, pert_idose, compound_plate, pert_time, project_id) %>%
  # LFC and LFC.cb values will be medians across replicates
  dplyr::summarize(LFC = median(LFC, na.rm = TRUE),
                   LFC.cb = median(LFC.cb, na.rm = TRUE),
                   .groups = "drop") %>%
  dplyr::ungroup()

#---- Compute growth rates ----
# control (base) and DMSO
if (calc_gr) {
  print("Calculating GR metrics")
  CONTROL_GR <- tryCatch(expr = {base_normalized %>%
      dplyr::group_by(pert_time, ccle_name, rid, pool_id, culture) %>%  # no compound to group by
      dplyr::summarize(mLMFI.c = median(LMFI),
                       n.c = n(),
                       var.c = (mad(LMFI)^2/n.c) * pi/2,
                       .groups = "drop") %>%  # n = replicates (~300)
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
                                           var.d = (mad(LMFI)^2/n.d) * pi/2,
                                           .groups = "drop") %>%
                          dplyr::select(-n.d),
                        by = c("ccle_name", "rid", "pool_id", "culture")) %>%
      dplyr::mutate(base_day_num = as.numeric(str_sub(pert_base_time, 1, -2))/24)
  }, error = function(e) {
    return(NA)
  })

  # treatment
  GR_TABLE <- tryCatch(expr = {logMFI_normalized %>%
      # now group by compound
      dplyr::group_by(pert_mfc_id, pert_type, pert_name, pert_dose, pert_idose,
                      ccle_name, rid, pool_id, culture, pert_time, project_id) %>%
      dplyr::summarize(mLMFI.t = median(LMFI),
                       n.t = n(),
                       var.t = (mad(LMFI)^2/n.t) * pi/2,
                       .groups = "drop") %>%
      dplyr::select(-n.t) %>%
      dplyr::inner_join(CONTROL_GR,
                        by = c("ccle_name", "rid", "pool_id", "culture", "pert_time")) %>%
      dplyr::ungroup()
  }, error = function(e) {
    return(tibble())
  })

  # combined
  GR_TABLE <- tryCatch(expr = {GR_TABLE %>%
      # calculate control change (DMSO - base)/(t - base day),
      # treatment change (treatment - DMSO)/t - control,
      # use to calculate Z (treatment/control) and GR (2^Z - 1)
      dplyr::mutate(control_lfc = (mLMFI.d - mLMFI.c)/(assay_length - base_day_num),
                    treatment_control_lfc = (mLMFI.t - mLMFI.d)/(assay_length),
                    treatment_lfc = treatment_control_lfc + control_lfc,
                    Z = treatment_lfc/control_lfc,
                    var.treatment = (var.t/assay_length^2) + (var.d/(assay_length - base_day_num)^2) +
                      (var.c*(1/(assay_length-base_day_num) - 1/assay_length)^2),
                    var.control = (var.c + var.d)/(assay_length - base_day_num)^2,
                    GR = (2^Z) - 1) %>%
      dplyr::distinct(pert_mfc_id, pert_type, pert_name, pert_dose, pert_idose,
                      rid, ccle_name, culture, pool_id, pert_time, assay_length, base_day_num,
                      control_lfc, treatment_lfc, Z, var.treatment, var.control, GR) %>%
      dplyr::rename(base_day = base_day_num)
  }, error = function(e) {
    return(tibble())
  })
} else {
  GR_TABLE <- tibble()
}

#---- Write results ----
readr::write_csv(LFC_TABLE, paste0(out_dir, "/LFC_TABLE.csv"))
readr::write_csv(LFC_COLLAPSED_TABLE, paste0(out_dir, "/LFC_COLLAPSED_TABLE.csv"))

# GR data if it exists
if(calc_gr) {
  readr::write_csv(GR_TABLE, paste0(out_dir, "/GR_TABLE.csv"))
}

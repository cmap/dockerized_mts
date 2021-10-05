# Script to go from normalized logMFI values to LFC

# import necessary libraries and functions using MTS_functions.R
suppressMessages(source("./src/lfc_functions.R"))

#---- Read arguments ----
# initialize parser
parser <- ArgumentParser()
# specify our desired options
parser$add_argument("-b", "--base_dir", default="", help="Input directory")
parser$add_argument("-o", "--out", default=getwd(), help = "Output path. Default is working directory")
parser$add_argument("-g", "--calc_gr", default=0, help = "Boolean (1 or 0). Should GR metrics be calculated?")

# get command line options, if help option encountered print help and exit
args <- parser$parse_args()

base_dir <- args$base_dir
out_dir <- args$out
calc_gr <- as.numeric(args$calc_gr)

if (!dir.exists(out_dir)) {dir.create(out_dir, recursive = T)}

#---- Load the data ----
print("Loading data and pre-processing")
logMFI_normalized <- data.table::fread(paste0(base_dir, "/logMFI.csv"))

# split into base and final reading
base_normalized <- logMFI_normalized %>%
  dplyr::filter(str_detect(prism_replicate, "BASE"))
logMFI_normalized %<>%
  dplyr::filter(str_detect(prism_replicate, "BASE", negate = T))
plates <- distinct(logMFI_normalized, prism_replicate) %>%
  dplyr::mutate(compound_plate = stringr::word(prism_replicate, 1,
                                               sep = fixed("_")))
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
LFC_TABLE %<>%
  dplyr::group_by(prism_replicate, ccle_name, culture, pert_time) %>%
  dplyr::mutate(LFC = logMFI.norm - median(logMFI.norm[pert_type == "ctl_vehicle"])) %>%
  dplyr::ungroup() %>%
  dplyr::select(-logMFI, -logMFI.norm)

#---- Correct for pool effects ----
print("ComBat correcting")
LFC_TABLE %<>%
  dplyr::mutate(x_project_id = pert_iname == "KAT6A_2") %>%
  dplyr::filter(!pert_type %in% c("ctl_vehicle", "ctl_untrt")) %>%
  dplyr::left_join(plates, by = c("prism_replicate")) %>%
  tidyr::unite(col = "condition", pert_iname, pert_dose, compound_plate, pert_time, any_of("x_project_id"),
               sep = "::", remove = FALSE) %>%
  split(.$condition) %>%
  purrr::map_dfr(~dplyr::mutate(.x, LFC.cb = apply_combat(.))) %>%
  dplyr::select(-condition)

# TODO: fix grouping variables
#---- Make collapsed LFC table ----
LFC_COLLAPSED_TABLE <- LFC_TABLE %>%
  dplyr::select(ccle_name, culture, pool_id, pert_iname, pert_id, pert_dose,
                pert_idose, compound_plate, pert_vehicle, pert_time, LFC, LFC.cb,
                any_of(c("x_mixture_contents", "x_mixture_id", "x_project_id"))) %>%
  dplyr::group_by(across(.cols = !contains("LFC"))) %>%
  # LFC and LFC.cb values will be medians across replicates
  dplyr::summarize(LFC = median(LFC, na.rm = TRUE),
                   LFC.cb = median(LFC.cb, na.rm = TRUE),
                   .groups = "drop")

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
      dplyr::group_by(pert_id, pert_type, pert_iname, pert_dose, pert_idose, x_mixture_contents,
                      x_mixture_id, ccle_name, rid, pool_id, culture, pert_time, x_project_id) %>%
      dplyr::summarize(mLMFI.t = median(LMFI),
                       n.t = n(),
                       var.t = (mad(LMFI)^2/n.t) * pi/2,
                       .groups = "drop") %>%
      dplyr::select(-n.t) %>%
      dplyr::inner_join(CONTROL_GR,
                        by = c("ccle_name", "rid", "pool_id", "culture", "pert_time"))
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
      dplyr::distinct(pert_id, pert_type, pert_iname, pert_dose, pert_idose,
                      x_project_id, x_mixture_contents, x_mixture_id,
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

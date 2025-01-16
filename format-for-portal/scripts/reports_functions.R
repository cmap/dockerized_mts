
# I ignored this snippet accross the board!! -----
# Need to check with Anup and include accordingly.
# if (!params$is_combination){
#   if (all(is.na(corr_table$pert_dose %>% unique()))) corr_table$pert_dose <- "NA"
#   if (all(is.na(disc_table$pert_dose %>% unique()))) disc_table$pert_dose <- "NA"
#   if (all(is.na(model_table$pert_dose %>% unique()))) model_table$pert_dose <- "NA"
#   if (all(is.na(rf_table$pert_dose %>% unique()))) rf_table$pert_dose <- "NA"
#
#   corr_table %<>%
#     dplyr::mutate(
#       pert_dose = ifelse(pert_dose %in% c("log2.auc", "log2.ic50"),
#                          paste0(pert_iname, " ", pert_dose, "\n", added_compounds, " ", added_doses),
#                          pert_dose),
#       pert_iname = unique(LFC$pert_iname))
#
#   disc_table %<>%
#     dplyr::mutate(
#       pert_dose = ifelse(pert_dose %in% c("log2.auc", "log2.ic50"),
#                          paste0(pert_iname, " ", pert_dose, "\n", added_compounds, " ", added_doses),
#                          pert_dose),
#       pert_iname = unique(LFC$pert_iname))
#
# }

# ------


#' Create "correlation_analysis_data_table.csv"
#' 
#' Please make sure the input directory contains continuous_associations.csv with
#' the following columns: pert_plate, pert_id, pert_dose, feature_type, feature, coef, q.val, rank, pert_time (!)
#' 
#' # Warning: "feature" columns should be formatted as "FEATURE.TYPE_FEATURE" where underscore is used as the delimeter.
#' 
#' DISCUSSION POINTS: 
#' 1. Dropping pert_time filter but keeping the column! Analytics to make sure unwanted time points are not included into the list, software to make sure the time point is tracked. 
#' 2. Included feature_types were implicitly controlled in the markdowns. I propose to keep everything in the lists, and move the filtering to either to the biomarker module or to the portal itself.
#' 3. Filtering based on effect size or significance also happens here, I left it here for now.
#' 
#' Output table is named as correlation_analysis_data_table.csv with the following columns:
#' pert_plate, pert_id, pert_dose, feature_type, feature, coef, q.val, rank, neg_log10_qval, pert_time
#'
#' @param in_path : Directory to look for "continuous_associations.csv" - make sure to include a "/" as the last character
#' @param out_path : Directory to save "correlation_analysis_data_table.csv" - make sure to include a "/" as the last character
#'
#' @return 
#' @export
#' @examples
#' create_correlation_analysis_data_table("input/report/single_compound/BRD-A12230535/")
#' 
create_correlation_analysis_data_table <- function(in_path, out_path = NULL) {
  require(dplyr)
  require(data.table)
  require(magrittr)
  suppressMessages(require(tidyverse))
  
  # if the output path is not provided, use the input path
  if(is.null(out_path)){
    out_path <- in_path
  }
  
  # check if the continuous_associations.csv is in the input directory
  if(! "continuous_associations.csv" %in% dir(in_path)){
    stop("continuous_associations.csv is not in the input directory!")
  }

  # load the continuous_associations table
  continous_associations <- data.table::fread(file.path(in_path, "continuous_associations.csv"))
  
  
  # check if the input table populated
  if(nrow(continous_associations) == 0){
    stop("continuous_associations.csv is empty!")
  } 

  # check for missing critical columns
  necessary_columns <- c("pert_plate", "pert_id", "pert_dose", "feature_type", "feature", "coef", "q.val", "rank", "pert_time")
  if(any(!necessary_columns %in% colnames(continous_associations))){
    stop(paste0(paste0(setdiff(necessary_columns, colnames(continous_associations)), collapse = ", "),
                " are missing in continuous_associations.csv"))
  } 
  
  # save the output table 
  continous_associations %>% 
    dplyr::filter(q.val < 0.1) %>% 
    dplyr::group_by(sign(coef), pert_iname, pert_dose, pert_time) %>% 
    dplyr::arrange(q.val) %>%
    dplyr::mutate(sign_rank = 1:n(), neg_log10_qval=-log10(q.val)) %>%
    dplyr::ungroup() %>%
    dplyr::filter(rank <= 250 | sign_rank <= 25) %>% 
    # dplyr::filter(pert_time == "120H") # !!!
    dplyr::mutate(feature = word(feature, 2, -1, sep = "_")) %>% 
    dplyr::distinct(pert_plate, pert_id, pert_dose, feature_type, feature, coef, q.val, rank, pert_time, neg_log10_qval) %>% 
    dplyr::mutate(pert_dose = ifelse(!is.na(as.numeric(pert_dose)), signif(as.numeric(pert_dose), 5), pert_dose)) %>% 
    write_csv(file.path(out_path, "correlation_analysis_data_table.csv"))

}


#' Create "experimental_details.csv"
#' 
#' Please make sure the input directory contains only a single file csv with its name starting with "LEVEL5_", and the file should contain the following columns
#' the following columns:  pert_plate, pert_id, pert_iname, pert_dose, pert_idose, pert_time
#' 
#' Output table is named as experimental_details.csv with the following columns:
#' pert_plate, pert_id, pert_iname, pert_dose, pert_idose, pert_time
#'
#' @param in_path : Directory to look for "LEVEL5_*.csv"  
#' @param out_path : Directory to save "experimental_details.csv"
#'
#' @return 
#' @export
#' @examples
#' create_experimental_details("input/report/combination_compound/BRD-K32107296_BRD-K92041145/")
#' 
create_experimental_details <- function(in_path, out_path = NULL){
  require(dplyr)
  require(data.table)
  require(magrittr)
  require(stringr)
  suppressMessages(require(tidyverse))
  
  # if the output path is not provided, use the input path
  if(is.null(out_path)){
    out_path <- in_path
  }
  
  # identify the LEVEL5 file
  files = dir(in_path); files = files[!is.na(files)]
  file = files[word(files, 1, sep = fixed("_")) == "LEVEL5"]
  
  # check if the LEVEL5_LFC_*.csv is in the input directory
  if(length(file) != 1){
    stop("LEVEL5 file could not be identified in the input directory!")
  }
  
  # load the level 5 table
  lfc <- data.table::fread(paste0(in_path, file))
  
  # check if the input table populated
  if(nrow(lfc) == 0){
    stop(paste0(file, " is empty!"))
  } 
  
  # check for missing critical columns
  necessary_columns <- c("pert_plate", "pert_id", "pert_iname", "pert_dose", "pert_idose", "pert_time")
  if(any(!necessary_columns %in% colnames(lfc))){
    stop(paste0(paste0(setdiff(necessary_columns, colnames(lfc)), collapse = ", "), 
                " are missing in LEVEL5 file."))
  } 
  
  # save the output table
  lfc %>% 
    dplyr::distinct(pert_plate, pert_id, pert_iname, pert_dose, pert_idose, pert_time) %>% 
    dplyr::group_by(pert_iname) %>% 
    dplyr::arrange(pert_dose) %>% 
    dplyr::mutate(pert_dose = ifelse(!is.na(as.numeric(pert_dose)), signif(as.numeric(pert_dose), 5), pert_dose)) %>% 
    write_csv(file.path(out_path, "experimental_details.csv"))
}


#' Create "lineage_enrichment_volcano_data.csv"
#' 
#' Please make sure the input directory contains "discrete_associations.csv" and a single file with its name startigh with "LEVEL5_".
#' Additionally, make sure the lineage_path directory contains "lineages.csv". 
#' 
#' Expected mandatory columns: 
#' "LEVEL5_*.csv": ccle_name
#' "lineages.csv": ccle_name, lineage, lin_abbreviation, lineage_subtype, lin_sub_abbreviation
#' "discrete_associations.csv": pert_iname, pert_dose, pert_time, feature_type, feature, q.value, effect_size
#' Note, feature_type is expected to be equal to "LIN" for lineage associations, and corresponding features has the naming convention "LIN_*".
#' 
#' Output table is named as lineage_enrichment_volcano_data.csv with the following columns:
#' pert_plate, pert_id, pert_iname,  pert_dose, lineage, n_lines, effect_size, neg_log10_qval , pert_time
#' 
#' DISCUSSION POINTS: 
#' 1. lineage.csv is not maintained at all! I think we should pull it out from either cellDB or models.csv. Lineages that doesn't appear in that table are silently dropped.
#' 2. n_lines is poorly calculated and needs to be updated. The new biomarker module actually has better metrics, so I propose updating this to the biomarker module update. 
#' 3. Treating lineage and mutation as special makes it harder to include new discrete biomarker types!
#' 4. I dropped rounding of effect sizes. I think those steps should be taken while visualizing. 
#' 
#'
#' @param in_path : Directory to look for "LEVEL5_*.csv" and "discrete_associations.csv"
#' @param lineage_path : Directory to look for "lineages.csv"
#' @param out_path : Directory to save "lineage_enrichment_volcano_data.csv"
#'
#' @return 
#' @export
#' @examples
#' create_lineage_enrichment_volcano_data("input/report/combination_compound/BRD-K32107296_BRD-K92041145/", "input/")
#' 
create_lineage_enrichment_volcano_data <- function(in_path, lineage_path,  out_path = NULL){
  require(dplyr)
  suppressMessages(require(tidyverse))
  require(data.table)
  require(magrittr)
  
  # if the output path is not provided, use the input path
  if(is.null(out_path)){
    out_path <- in_path
  }
  
  # check if the lineages.csv is in the lineage directory
  if(! "lineages.csv" %in% dir(lineage_path)){
    stop("lineages.csv is not in the lineage directory!")
  }
  
  lineages <- data.table::fread(paste0(lineage_path, "lineages.csv"))  # %>% dplyr::inner_join(LFC %>% dplyr::distinct(ccle_name), by = "ccle_name")
  
  # check if the lineages.csv has the critical columns
  necessary_columns <- c("ccle_name", "lineage", "lin_abbreviation", "lineage_subtype", "lin_sub_abbreviation")
  if(any(!necessary_columns %in% colnames(lineages))){
    stop(paste0(paste0(setdiff(necessary_columns, colnames(lineages)), collapse = ", "), 
                " are missing in lineages.csv"))
  } 
  
  # identify the LEVEL5 file
  files = dir(in_path); files = files[!is.na(files)]
  file = files[word(files, 1, sep = fixed("_")) == "LEVEL5"]
  # check if the LEVEL5_LFC_*.csv is in the input directory
  if(length(file) != 1){
    stop("LEVEL5 file could not be identified in the input directory!")
  }
  ccle_names <- data.table::fread(paste0(in_path, file))$ccle_name %>% unique()
  
  # check if lineages.csv and data matches
  lineages %<>% dplyr::filter(ccle_name %in% ccle_names)   
  if(nrow(lineages) == 0){
    stop("lineages.csv and LEVEL5_*.csv does not have any common cell lines!")
  }
  
  # check if discrete_associations.csv is in the input directory
  if(! "discrete_associations.csv" %in% dir(in_path)){
    stop("discrete_associations.csv is not in the input directory!")
  }
  
  # load the discrete_associations table
  discrete_associations <- data.table::fread(paste0(in_path, "discrete_associations.csv"))
  
  # check if the discrete_associations.csv has the critical columns
  necessary_columns <- c("pert_iname", "pert_dose", "pert_time", "feature_type", "feature", "q.value", "effect_size")
  if(any(!necessary_columns %in% colnames(discrete_associations))){
    stop(paste0(paste0(setdiff(necessary_columns, colnames(discrete_associations)), collapse = ", "), 
                " are missing in discrete_associations.csv"))
  } 
  
  # reshape and filter lineage table
  lineages <- lineages %>%
    dplyr::select(ccle_name, lineage, lin_abbreviation) %>%
    dplyr::bind_rows(lineages %>%
                       dplyr::select(ccle_name, lineage_subtype, lin_sub_abbreviation) %>%
                       dplyr::rename(lineage = lineage_subtype,
                                     lin_abbreviation = lin_sub_abbreviation)) %>%
    dplyr::distinct(ccle_name, lineage, lin_abbreviation) %>% 
    dplyr::group_by(lineage, lin_abbreviation) %>% 
    dplyr::mutate(n_lines = n()) %>% 
    dplyr::ungroup() %>% 
    dplyr::filter(n_lines >= 5)
  
  # filter and save the lineage associations
  discrete_associations %>%
    dplyr::mutate(feature = word(feature, 2, -1, sep = "_"),
                  neg_log10_qval = -log10(q.value)) %>% 
    dplyr::filter(feature_type == "LIN") %>% 
    dplyr::rename(lineage = feature) %>% 
    dplyr::inner_join(lineages) %>% 
    dplyr::distinct(pert_plate, pert_id, pert_iname,  pert_dose, lineage, n_lines, effect_size, neg_log10_qval , pert_time) %>%
    dplyr::mutate(pert_dose = ifelse(!is.na(as.numeric(pert_dose)), signif(as.numeric(pert_dose), 5), pert_dose)) %>% 
    write_csv(file.path(out_path, "lineage_enrichment_volcano_data.csv"))
}


#' Create "lineage_enrichment_boxplot_v2.csv"
#' 
#' Please make sure the input directory contains "DRC_TABLE.csv" for dose-response data or a single file starting with "LEVEL5_" for single dose data.
#' Additionally, make sure the lineage_path directory contains "lineages.csv". 
#' 
#' Expected mandatory columns: 
#' "DRC_TABLE.csv" or "LEVEL5_*.csv":pert_plate, varied_iname (or pert_iname), varied_id (or pert_id), ccle_name, culture, pert_time   
#' "lineages.csv": depmap_id, ccle_name, lineage, lineage_subtype
#' 
#' Output table is named as lineage_enrichment_boxplot_v2.csv with the following columns:
#' pert_plate, pert_id, pert_iname, data_type, data, lineage, lineage_subtype,  depmap_id, culture, ccle_name, pert_time
#' 
#' DISCUSSION POINTS: 
#' 1. depmap_id is not carried in DRC_TABLE.csv! 
#' 2. maintainance of lineages.csv.
#' 3. LFC_cb is hard-coded and probably will not be there in long term.
#'
#' @param in_path : Directory to look for "DRC_TABLE.csv" or "LEVEL5_*.csv"  
#' @param lineage_path : Directory to look for "lineages.csv"
#' @param out_path : Directory to save "lineage_enrichment_boxplot_v2.csv"
#'
#' @return 
#' @export
#' @examples
#' create_lineage_enrichment_boxplot_v2("input/report/combination_compound/BRD-K32107296_BRD-K92041145/", "input/")
#' 
create_lineage_enrichment_boxplot_v2 <- function(in_path, lineage_path,  out_path = NULL){
  require(dplyr)
  suppressMessages(require(tidyverse))
  require(data.table)
  require(magrittr)
  
  # if the output path is not provided, use the input path
  if(is.null(out_path)){
    out_path <- in_path
  }
  
  
  necessary_columns_lineage <- c("depmap_id", "ccle_name", "lineage", "lineage_subtype")
  necessary_columns_data <- c("pert_plate", "pert_id", "pert_iname", "ccle_name", "culture", "pert_time")
  
  
  # check if the lineages.csv is in the lineage directory
  if(! "lineages.csv" %in% dir(lineage_path)){
    stop("lineages.csv is not in the lineage directory!")
  }

  lineages <- data.table::fread(paste0(lineage_path, "lineages.csv"))  

  # check if the lineages.csv has the critical columns
  if(any(!necessary_columns_lineage %in% colnames(lineages))){
    stop(paste0(paste0(setdiff(necessary_columns_lineage, colnames(lineages)), collapse = ", "), 
                " are missing in lineages.csv"))
  }

  # check if DRC_TABLE.csv is in the input directory
  if(! "DRC_TABLE.csv" %in% dir(in_path)){

    # identify the LEVEL5 file
    files = dir(in_path); files = files[!is.na(files)]
    file = files[word(files, 1, sep = fixed("_")) == "LEVEL5"]
    # check if the LEVEL5_LFC_*.csv is in the input directory
    if(length(file) != 1){
      stop("LEVEL5 file or DRC_TABLE could not be identified in the input directory!")
    }
    DATA <- data.table::fread(paste0(in_path, file))
  
    if(any(!c(necessary_columns_data, "LFC_cb") %in% colnames(DATA))){
      stop(paste0(paste0(setdiff(necessary_columns_data, colnames(DATA)), collapse = ", "), 
                  " are missing in LEVEL5 file."))
    } 
    
    DATA %<>% 
      dplyr::distinct(pert_plate, pert_id, pert_dose) %>% 
      dplyr::count(pert_id) %>% 
      dplyr::filter(n == 1) %>% 
      dplyr::left_join(DATA) %>% 
      dplyr::mutate(data = LFC_cb, data_type = "LFC_cb")
    
    if(nrow(DATA) == 0){
      stop("DRC_TABLE could not be found, but LFC data is not single point!")
    }

    else{
      stop("LEVEL5 file or DRC_TABLE could not be identified in the input directory!") 
    }
  }else{
    DATA <- data.table::fread(paste0(in_path, "DRC_TABLE.csv"))
    
    # Replacing "varied_*" column names with "pert_*" ones!
    colnames(DATA) <- gsub("^varied_", "pert_", colnames(DATA))
    
    if(any(!c(necessary_columns_data, "auc") %in% colnames(DATA))){
      stop(paste0(paste0(setdiff(necessary_columns_data, colnames(DATA)), collapse = ", "), 
                  " are missing in DRC_TABLE.csv"))
    } 
    
    DATA %<>% 
      dplyr::mutate(data = auc, data_type = "auc")
  }
  
  # saving the file
  DATA %>% 
    dplyr::inner_join(lineages, by = "ccle_name") %>%
    dplyr::select(any_of(unique(c(necessary_columns_data, necessary_columns_lineage, "data", "data_type")))) %>% 
    dplyr::distinct() %>% 
    write_csv(file.path(out_path, "lineage_enrichment_boxplot_v2.csv"))
  
}


#' Create "viability.csv"
#' 
#' Please make sure the input directory contains only a single file csv with its name starting with "LEVEL5_", and the file should contain the following columns
#' the following columns:  pert_plate, pert_id, pert_iname, pert_dose, pert_vehicle, ccle_name, pool_id, culture, LFC_cb, pert_time
#' 
#' Output table is named as viability.csv with the following columns:
#' pert_plate, pert_id, pert_iname, pert_dose, pert_vehicle, ccle_name, pool_id, culture, LFC_cb, pert_time, viab
#' 
#' DISCUSSION POINTS: 
#' 1. Rounding happening in the code, I think this should eventually move to the visualization. 
#' 2. Cell lines are maintained by ccle_names (as opposed to the depmap_id's).
#' 3. LFC_cb was overwritten by LFC in the original code, I removed it! 
#'
#' @param in_path : Directory to look for "LEVEL5_*.csv"  
#' @param out_path : Directory to save "viability.csv"
#'
#' @return 
#' @export
#' @examples
#' create_viability("input/report/combination_compound/BRD-K32107296_BRD-K92041145/")
#' 
create_viability <- function(in_path, out_path = NULL){
  require(dplyr)
  suppressMessages(require(tidyverse))
  require(data.table)
  require(magrittr)
  require(stringr)
  
  # if the output path is not provided, use the input path
  if(is.null(out_path)){
    out_path <- in_path
  }
  
  # identify the LEVEL5 file
  files = dir(in_path); files = files[!is.na(files)]
  file = files[word(files, 1, sep = fixed("_")) == "LEVEL5"]
  
  # check if the LEVEL5_LFC_*.csv is in the input directory
  if(length(file) != 1){
    stop("LEVEL5 file could not be identified in the input directory!")
  }
  
  # load the level 5 table
  lfc <- data.table::fread(paste0(in_path, file))
  
  # check if the input table populated
  if(nrow(lfc) == 0){
    stop(paste0(file, " is empty!"))
  } 
  
  # check for missing critical columns
  necessary_columns <- c("pert_plate", "pert_id", "pert_iname", "pert_dose", "pert_vehicle", "ccle_name", "pool_id", "culture", "LFC_cb", "pert_time")
  if(any(!necessary_columns %in% colnames(lfc))){
    stop(paste0(paste0(setdiff(necessary_columns, colnames(lfc)), collapse = ", "), 
                " are missing in LEVEL5 file."))
  } 
  
  # save the output table
  lfc %>% 
    dplyr::distinct(pert_plate, pert_id, pert_iname, pert_dose, pert_vehicle, ccle_name, pool_id, culture, LFC_cb, pert_time) %>% 
    dplyr::mutate(viab = signif(2^LFC_cb, 3),  # !!!! I think these should be removed! 
                  LFC_cb = signif(LFC_cb, 3)) %>% 
    write_csv(file.path(out_path, "viability.csv"))
}


#' Create multivariate_biomarker_files :
#'  "multivariate_biomarker_info_table.csv",
#'  "multivariate_biomarker_ccle_volcano.csv",  "multivariate_biomarker_complete_volcano.csv",
#'  "multivariate_biomarker_ccle_data_table.csv",  "multivariate_biomarker_complete_data_table.csv"
#'
#' Please make sure the input directory contains model_table.csv and RF_table.csv with the following columns: 
#' model_table.csv: pert_plate, pert_id, pert_iname, pert_dose, model, PearsonScore, R2
#' RF_table.csv: pert_plate, pert_id, pert_iname, pert_time, pert_dose, model, feature, rank, RF.imp.mean, RF.imp.stability, RF.imp.sd
#' 
#' For combinations, additionally, we need added_compounds and added_doses columns too for both files.
#' As it is "model" column should take one of two values: "ccle" or "all".
#' 
#' DISCUSSION POINTS: 
#' 1. Included pert_time for future use.
#' 2. Rounding of dose is included in the preparation code.
#' 3. multivariate_biomarker_info_table.csv and other files has different pert_dose notation for combinations! 
#' 4. Missing check: model column should only take values of "ccle" or "all" 
#' 
#' Output tables and correspondign columns are listed below:
#' multivariate_biomarker_info_table.csv: pert_plate, pert_id, pert_iname, pert_time, pert_dose, model, R2, PearsonScore
#' multivariate_biomarker_ccle_volcano.csv and multivariate_biomarker_complete_volcano.csv : pert_plate, pert_id, pert_time, feature, R2, PearsonScore, RF.imp.mean, pert_iname, pert_dose
#' multivariate_biomarker_ccle_data_table.csv and multivariate_biomarker_complete_data_table.csv : pert_plate, pert_id, pert_time, feature, R2, rank, RF.imp.mean, RF.imp.stability, RF.imp.sd, pert_iname, pert_dose
#'
#' @param in_path : Directory to look for "model_table.csv" - make sure to include a "/" as the last character
#' @param out_path : Directory to save output tables. - make sure to include a "/" as the last character
#'
#' @return 
#' @export
#' @examples
#' create_multivariate_biomarker_files("input/report/single_compound/BRD-A12230535/")
#' 
create_multivariate_biomarker_files <- function(in_path, out_path = NULL){
  require(dplyr)
  suppressMessages(require(tidyverse))
  require(data.table)
  require(magrittr)
  
  # if the output path is not provided, use the input path
  if(is.null(out_path)){
    out_path <- in_path
  }
  
  # check if the model_table.csv is in the input directory
  if(! "model_table.csv" %in% dir(in_path)){
    stop("model_table.csv is not in the input directory!")
  }
  
  # load the model_table
  model_table <- data.table::fread(paste0(in_path, "model_table.csv"))
  
  
  # check if the input table populated
  if(nrow(model_table) == 0){
    stop("model_table.csv is empty!")
  } 
  
  # check for missing critical columns - note for combinations we need added_compounds, added_ids, added_doses too ! 
  necessary_columns <- c("pert_plate", "pert_id", "pert_iname", "pert_time", "pert_dose", "model", "R2", "PearsonScore")
  if(any(!necessary_columns %in% colnames(model_table))){
    stop(paste0(paste0(setdiff(necessary_columns, colnames(model_table)), collapse = ", "), 
                " are missing in model_table.csv"))
  }
  

  # check if the RF_table.csv is in the input directory
  if(! "RF_table.csv" %in% dir(in_path)){
    stop("RF_table.csv is not in the input directory!")
  }
  
  # load the rf_table
  rf_table <- data.table::fread(paste0(in_path, "RF_table.csv")) 
  
  # check for missing critical columns - note for combinations we need added_compounds, added_ids, added_doses too ! 
  necessary_columns <- c("pert_plate", "pert_id", "pert_iname", "pert_time", "pert_dose", "model", "feature", "rank", "RF.imp.mean", "RF.imp.stability", "RF.imp.sd")
  if(any(!necessary_columns %in% colnames(rf_table))){
    stop(paste0(paste0(setdiff(necessary_columns, colnames(rf_table)), collapse = ", "), 
                " are missing in RF_table.csv"))
  }
  

  # modify the dose column for rf_table 
  rf_table <- rf_table %>%
    dplyr::left_join(model_table) %>%
    dplyr::mutate(pert_dose = ifelse(!is.na(as.numeric(pert_dose)), signif(as.numeric(pert_dose), 5), pert_dose))
  
  if("added_doses" %in% rownames(rf_table)){
    rf_table <- rf_table %>% 
      dplyr::mutate(pert_dose = ifelse(pert_dose %in% c("log2.auc", "log2.ic50"),
                                       paste0(pert_iname, " ", pert_dose, "\n", added_compounds, " ", added_doses),
                                       pert_dose)) # note this makes model_table and rf_table has different pert_dose columns! 
  }
  
  
  # save the output tables 
  multivariate_biomarker_info_table = model_table %>%
    dplyr::distinct(pert_plate, pert_id, pert_iname, pert_time, pert_dose, model, R2, PearsonScore) %>%
    dplyr::mutate(R2 = signif(R2, 3),
                  PearsonScore = signif(PearsonScore, 3),
                  pert_dose = ifelse(!is.na(as.numeric(pert_dose)),signif(as.numeric(pert_dose), 5), pert_dose)) %>%
    dplyr::arrange(desc(R2)) %>% 
    write_csv(file.path(out_path, "multivariate_biomarker_info_table.csv"))
  
  rf_table %>%
    dplyr::filter(model == "ccle", rank == 1) %>%
    dplyr::distinct(pert_plate, pert_id, pert_time, feature, R2, PearsonScore, RF.imp.mean, pert_iname, pert_dose) %>%
    write_csv(file.path(out_path, "multivariate_biomarker_ccle_volcano.csv"))
  
  
  rf_table %>%
    dplyr::filter(model == "ccle", rank <= 100) %>%
    dplyr::distinct(pert_plate, pert_id, pert_time, feature, R2, rank, RF.imp.mean, RF.imp.stability, RF.imp.sd, pert_iname, pert_dose) %>%
    dplyr::mutate(RF.imp.mean = signif(RF.imp.mean, 3), 
                  RF.imp.sd = signif(RF.imp.sd, 3), 
                  RF.imp.stability = signif(RF.imp.stability, 3), 
                  R2 = signif(R2, 3)) %>% 
    dplyr::arrange(rank) %>%
    write_csv(file.path(out_path, "multivariate_biomarker_ccle_data_table.csv"))
  
  
  rf_table %>%
    dplyr::filter(model == "all", rank == 1) %>%
    dplyr::distinct(pert_plate, pert_id, pert_time, feature, R2, PearsonScore, RF.imp.mean, pert_iname, pert_dose) %>%
    write_csv(file.path(out_path, "multivariate_biomarker_complete_volcano.csv"))
  
  
  rf_table %>%
    dplyr::filter(model == "all", rank <= 100) %>%
    dplyr::distinct(pert_plate, pert_id, pert_time, feature, R2, rank, RF.imp.mean, RF.imp.stability, RF.imp.sd, pert_iname, pert_dose) %>%
    dplyr::mutate(RF.imp.mean = signif(RF.imp.mean, 3), 
                  RF.imp.sd = signif(RF.imp.sd, 3), 
                  RF.imp.stability = signif(RF.imp.stability, 3), 
                  R2 = signif(R2, 3)) %>% 
    dplyr::arrange(rank) %>%
    write_csv(file.path(out_path, "multivariate_biomarker_complete_data_table.csv"))
}


#' Create "mutation_effect_volcano_plot_data.csv"
#' 
#' Please make sure the input directory contains "discrete_associations.csv" and a single file with its name startigh with "LEVEL5_".
#' Additionally, make sure the lineage_path directory contains "lineages.csv". 
#' 
#' Expected mandatory columns: 
#' "LEVEL5_*.csv": ccle_name
#' "lineages.csv": ccle_name, lineage, lin_abbreviation, lineage_subtype, lin_sub_abbreviation
#' "discrete_associations.csv": pert_iname, pert_dose, pert_time, feature_type, feature, q.value, effect_size
#' Note, feature_type is expected to be equal to "LIN" for lineage associations, and corresponding features has the naming convention "LIN_*".
#' 
#' Output table is named as mutation_effect_volcano_plot_data.csv with the following columns:
#' pert_plate, pert_id, pert_iname,  pert_dose, feature, n_lines, effect_size, neg_log10_qval , pert_time
#' 
#' DISCUSSION POINTS: 
#' 1. mutations.csv is not maintained at all! I think we should pull it out depmap_datasets.h5 or depmap directly. 
#' 2. n_lines is poorly calculated and needs to be updated. The new biomarker module actually has better metrics, so I propose updating this to the biomarker module update. 
#' 3. Treating lineage and mutation as special makes it harder to include new discrete biomarker types!
#' 4. I think the way we were calculating ranks (and filtering based on them) were wrong, so I updated that!
#' 5. I am not confident if the output columns are matching portal needs, need to confirm with Anup!!!
#'
#' @param in_path : Directory to look for "LEVEL5_*.csv" and "discrete_associations.csv"
#' @param mutation_path : Directory to look for "mutation.csv"
#' @param out_path : Directory to save "mutation_effect_volcano_data.csv"
#'
#' @return 
#' @export
#' @examples
#' create_mutation_effect_volcano_data("input/report/combination_compound/BRD-K32107296_BRD-K92041145/", "input/")
#' 
create_mutation_effect_volcano_plot_data <- function(in_path, mutation_path,  out_path = NULL){
  require(dplyr)
  suppressMessages(require(tidyverse))
  require(stringr)
  require(data.table)
  require(magrittr)
  
  # if the output path is not provided, use the input path
  if(is.null(out_path)){
    out_path <- in_path
  }
  
  # check if the mutations.csv is in the lineage directory
  if(! "mutations.csv" %in% dir(mutation_path)){
    stop("mutations.csv is not in the mutation directory!")
  }
  
  mutations <- data.table::fread(paste0(mutation_path, "mutations.csv"))  
  
  # check if the mutataions.csv has the critical columns
  necessary_columns <- c("ccle_name", "mutation")
  if(any(!necessary_columns %in% colnames(mutations))){
    stop(paste0(paste0(setdiff(necessary_columns, colnames(mutations)), collapse = ", "), 
                " are missing in mutations.csv"))
  } 
  
  
  
  # identify the LEVEL5 file
  files = dir(in_path); files = files[!is.na(files)]
  file = files[word(files, 1, sep = fixed("_")) == "LEVEL5"]
  # check if the LEVEL5_LFC_*.csv is in the input directory
  if(length(file) != 1){
    stop("LEVEL5 file could not be identified in the input directory!")
  }
  ccle_names <- data.table::fread(paste0(in_path, file))$ccle_name %>% unique()
  
  # check if mutations.csv and data matches
  mutations %<>% dplyr::filter(ccle_name %in% ccle_names)   
  
  if(nrow(mutations) == 0){
    stop("mutations.csv and LEVEL5_*.csv does not have any common cell lines!")
  }
  
  mutations <- mutations %>%
    dplyr::filter(ccle_name %in% ccle_names) %>% 
    dplyr::group_by(mutation) %>% 
    dplyr::mutate(n_lines = n()) %>% 
    dplyr::filter(n_lines >= 5)  %>%
    dplyr::ungroup()
  
  
  # check if discrete_associations.csv is in the input directory
  if(! "discrete_associations.csv" %in% dir(in_path)){
    stop("discrete_associations.csv is not in the input directory!")
  }
  
  # load the discrete_associations table
  discrete_associations <- data.table::fread(paste0(in_path, "discrete_associations.csv"))
  
  # check if the discrete_associations.csv has the critical columns
  necessary_columns <- c("pert_iname", "pert_dose", "pert_time", "feature_type", "feature", "q.value", "effect_size")
  if(any(!necessary_columns %in% colnames(discrete_associations))){
    stop(paste0(paste0(setdiff(necessary_columns, colnames(discrete_associations)), collapse = ", "), 
                " are missing in discrete_associations.csv"))
  } 
  
  
  # filter and save the mutation associations
  volcano_plot_data <- discrete_associations %>%
    dplyr::mutate(feature = word(feature, 2, -1, sep = "_"),
                  neg_log10_qval = -log10(q.value)) %>%
    dplyr::filter(feature_type == "MUT", q.value < 0.1) %>%
    dplyr::inner_join(mutations, by = c("feature" = "mutation")) %>%
    dplyr::mutate(pert_dose = ifelse(!is.na(as.numeric(pert_dose)),
                                     signif(as.numeric(pert_dose), 5),
                                     pert_dose),
                  is_positive = effect_size > 0)


  if(nrow(volcano_plot_data) > 0){
    volcano_plot_data %>%
      dplyr::group_by(is_positive, pert_iname, pert_dose, pert_plate, pert_time, pert_id) %>%
      dplyr::arrange(desc(abs(effect_size))) %>%
      dplyr::mutate(rank = 1:n()) %>%
      dplyr::arrange(q.value) %>%
      dplyr::mutate(sign_rank = 1:n()) %>%
      dplyr::ungroup() %>%
      dplyr::filter(rank <= 250 | sign_rank <= 25) %>%
      dplyr::distinct(pert_plate, pert_id, pert_iname,  pert_dose, feature, n_lines, effect_size, neg_log10_qval , pert_time) %>%
      dplyr::mutate(pert_dose = ifelse(!is.na(as.numeric(pert_dose)), signif(as.numeric(pert_dose), 5), pert_dose)) %>%
      write_csv(paste0(out_path, "mutation_effect_volcano_plot_data.csv"))
  }else{
    warning("Volcano plot table is empty!")
  }


}


#' Create "mutation_effect_boxplot_data.csv"
#' 
#' Please make sure the input directory contains "DRC_TABLE.csv" for dose-response data or a single file starting with "LEVEL5_" for single dose data.
#' Additionally, make sure the mutation directory contains "mutations.csv". 
#' 
#' Expected mandatory columns: 
#' "DRC_TABLE.csv" or "LEVEL5_*.csv":pert_plate, varied_iname (or pert_iname), varied_id (or pert_id), ccle_name, culture, pert_time   
#' "mutations.csv": ccle_name, mutation
#' 
#' Output table is named as mutation_effect_boxplot_data.csv with the following columns:
#' pert_plate, pert_id, pert_iname, data_type, data, depmap_id, culture, ccle_name, pert_time, gene, mut.type, minq
#' 
#' DISCUSSION POINTS: 
#' 1. depmap_id is not carried in DRC_TABLE.csv! 
#' 2. maintainance of mutations.csv
#' 3. LFC_cb is hard-coded and probably will not be there in long term.
#' 4. combination vs single compound logic was completely missing, I repeated the lineage_enrichment one here too
#' 5. I am not confident about the output columns, needs to be confirmed with Anup!!!
#'
#' @param in_path : Directory to look for "DRC_TABLE.csv" or "LEVEL5_*.csv"  
#' @param mutation_path : Directory to look for "mutations.csv"
#' @param out_path : Directory to save "mutation_effect_boxplot_data.csv"
#'
#' @return 
#' @export
#' @examples
#' create_mutation_effect_boxplot_data("input/report/combination_compound/BRD-K32107296_BRD-K92041145/", "input/")
#'
create_mutation_effect_boxplot_data <- function(in_path, mutation_path,  out_path = NULL){
  require(dplyr)
  require(data.table)
  require(magrittr)
  suppressMessages(require(tidyverse))
  
  # if the output path is not provided, use the input path
  if(is.null(out_path)){
    out_path <- in_path
  }
  
  
  necessary_columns_mutation <- c("ccle_name","mutation")
  necessary_columns_data <- c("pert_plate", "pert_id", "pert_iname", "ccle_name", "culture", "pert_time")
  
  
  # check if the mutations.csv is in the lineage directory
  if(! "mutations.csv" %in% dir(mutation_path)){
    stop("mutations.csv is not in the mutation directory!")
  }
  
  mutations <- data.table::fread(paste0(mutation_path, "mutations.csv"))  
  
  # check if the mutations.csv has the critical columns
  if(any(!necessary_columns_mutation %in% colnames(mutations))){
    stop(paste0(paste0(setdiff(necessary_columns_mutation, colnames(mutations)), collapse = ", "), 
                " are missing in mutations.csv"))
  }
  
  
  # check if DRC_TABLE.csv is in the input directory
  if(! "DRC_TABLE.csv" %in% dir(in_path)){
    
    # identify the LEVEL5 file
    files = dir(in_path); files = files[!is.na(files)]
    file = files[word(files, 1, sep = fixed("_")) == "LEVEL5"]
    # check if the LEVEL5_LFC_*.csv is in the input directory
    if(length(file) != 1){
      stop("LEVEL5 file or DRC_TABLE could not be identified in the input directory!")
    }
    DATA <- data.table::fread(paste0(in_path, file))
    
    if(any(!c(necessary_columns_data, "LFC_cb") %in% colnames(DATA))){
      stop(paste0(paste0(setdiff(necessary_columns_data, colnames(DATA)), collapse = ", "), 
                  " are missing in LEVEL5 file."))
    } 
    
    DATA %<>% 
      dplyr::distinct(pert_plate, pert_id, pert_dose) %>% 
      dplyr::count(pert_id) %>% 
      dplyr::filter(n == 1) %>% 
      dplyr::left_join(DATA) %>% 
      dplyr::mutate(data = LFC_cb, data_type = "LFC_cb")
    
    if(nrow(DATA) == 0){
      stop("DRC_TABLE could not be found, but LFC data is not single point!")
    }
    
    else{
      stop("LEVEL5 file or DRC_TABLE could not be identified in the input directory!") 
    }
  }else{
    DATA <- data.table::fread(paste0(in_path, "DRC_TABLE.csv"))
    
    # Replacing "varied_*" column names with "pert_*" ones!
    colnames(DATA) <- gsub("^varied_", "pert_", colnames(DATA))
    
    if(any(!c(necessary_columns_data, "auc") %in% colnames(DATA))){
      stop(paste0(paste0(setdiff(necessary_columns_data, colnames(DATA)), collapse = ", "), 
                  " are missing in DRC_TABLE.csv"))
    } 
    
    DATA %<>% 
      dplyr::mutate(data = auc, data_type = "auc")
  }
  
  # Selected mutations
  muts = mutations %>% 
    dplyr::filter(ccle_name %in% DATA$ccle_name) %>% # filtering out mutations that pertain to CCLE in DRC
    dplyr::count(mutation) %>% # count occurrence of mutation 
    dplyr::filter(n > 4) %>% # if less than 5 filter out 
    .$mutation
  
  
  # check if discrete_associations.csv is in the input directory
  if(! "discrete_associations.csv" %in% dir(in_path)){
    stop("discrete_associations.csv is not in the input directory!")
  }
  
  # load the discrete_associations table
  discrete_associations <- data.table::fread(paste0(in_path, "discrete_associations.csv"))
  
  # check if the discrete_associations.csv has the critical columns
  necessary_columns <- c("pert_iname", "pert_dose", "pert_time", "feature_type", "feature", "q.value", "effect_size")
  if(any(!necessary_columns %in% colnames(discrete_associations))){
    stop(paste0(paste0(setdiff(necessary_columns, colnames(discrete_associations)), collapse = ", "), 
                " are missing in discrete_associations.csv"))
  } 
  
  
  # choosing the genes to be highlighted
  top.genes <- discrete_associations %>% 
    dplyr::mutate(feature = word(feature, 2, -1, sep = "_"),
                  neg_log10_qval = -log10(q.value)) %>% 
    dplyr::filter(feature %in% muts, feature_type == "MUT",
                  pert_dose %in% union(DATA$pert_dose, "log2.auc")) %>% 
    dplyr::mutate(gene = word(feature, 2, sep = fixed("_")), 
                  mut.type = word(feature,1,-2, sep = fixed("_")))  %>% 
    dplyr::group_by(gene) %>%
    dplyr::summarise(minq = min(q.value, na.rm = T)) %>%  
    dplyr::top_n(20, -minq) %>% 
    dplyr::arrange(minq) %>% 
    dplyr::filter(minq < 0.1) %>%
    head(20)
  
  # organizing the data and saving the file.
  tibble(ccle_name = unique(DATA$ccle_name), status = 1) %>% 
    dplyr::inner_join(dplyr::mutate(top.genes, status = 1)) %>%
    dplyr::select(-status) %>% 
    dplyr::left_join( mutations %>% 
                        dplyr::mutate(gene = word(mutation, 2, sep = fixed("_")))) %>% 
    dplyr::mutate(mutation = ifelse(is.na(mutation), "wild_type", word(mutation, sep = fixed("_")))) %>% 
    dplyr::rename(mut.type = mutation) %>% 
    dplyr::left_join(DATA) %>% 
    dplyr::select(any_of(unique(c(necessary_columns_data, necessary_columns_mutation, "data", "data_type", "gene", "mut.type", "minq")))) %>% 
    dplyr::distinct() %>% 
    write_csv(file.path(out_path, "mutation_effect_boxplot_data.csv"))
}




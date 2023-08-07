suppressMessages(library(tidyverse))
suppressMessages(library(magrittr))
suppressMessages(library(useful))
suppressMessages(library(argparse))
suppressMessages(source("./src/metric_functions.R"))

#---- Read arguments ----
parser <- ArgumentParser()
# specify our desired options
parser$add_argument("-i", "--input_dir", default="", help="Input directory with one level 4 LFC file")
parser$add_argument("-o", "--out", default="", help="Output directory")

# get command line options, if help option encountered print help and exit
args <- parser$parse_args()
input_dir <- args$input_dir
out_dir <- args$out

lfc_files <- list.files(input_dir,pattern=("LEVEL4_LFC.*\\.csv$"), full.names=T)
combat_file = lfc_files[str_detect(lfc_files, "COMBAT")]

if (length(combat_file) == 1) {
  lfc_file = combat_file
} else if (length(lfc_files) == 1) {
  lfc_file <- lfc_files[[1]]
} else{
  stop(paste("Issue with LFC files found in directory: \n", toString(lfc_files)),
       call. = FALSE)
}

continous_files <- list.files(input_dir,pattern=("continuous_associations.csv$"), full.names=T)
discrete_files <- list.files(input_dir,pattern=("discrete_associations.csv$"), full.names=T)
random_forest.model_files <- list.files(input_dir,pattern=("model_table.csv$"), full.names=T)
random_forest.feats <- list.files(input_dir,pattern=("RF_table.csv$"), full.names=T)

# load the viability data ----
lfc <- data.table::fread(lfc_file)
# drc <- data.table::fread("data/MTS022_VALIDATION_COMPOUNDS_INTERNAL_DRC_TABLE.csv")

# load the biomarker data ----

continous <- data.table::fread(continous_files)
discrete <- data.table::fread(discrete_files)
random_forest.model <- data.table::fread(random_forest.model_files)
random_forest.feats <- data.table::fread(random_forest.feats)


# create the biomarker table first ----

RF.TABLE <- random_forest.feats %>%
  dplyr::filter(rank < 4) %>%
  dplyr::group_by(pert_iname, pert_id, pert_plate, pert_dose, model) %>%
  dplyr::arrange(rank) %>%
  dplyr::mutate(feature = paste0(feature, " (", round(RF.imp.mean, 3), ")")) %>%
  dplyr::summarise(feats = paste0(feature, collapse = ", ")) %>%
  dplyr::ungroup() %>%
  dplyr::left_join(random_forest.model %>%
                     dplyr::distinct(model, pert_iname, pert_id, pert_plate, pert_dose, PearsonScore)) %>%
  dplyr::mutate(model1 = paste0("RF.feats.", model),
                model = paste0("RF.score.", model)) %>%
  tidyr::pivot_wider(names_from = "model", values_from = "PearsonScore") %>%
  tidyr::pivot_wider(names_from = "model1", values_from = "feats") %>%
  dplyr::group_by(pert_iname, pert_id, pert_plate, pert_dose) %>%
  dplyr::summarise_all(function(x) x[!is.na(x)]) %>%
  dplyr::ungroup() %>%
  dplyr::mutate(pert_dose = ifelse(pert_dose %in% c("log2.auc", "log2.ic50"),
                                   pert_dose, as.character(as.numeric(pert_dose)))) # note this last operation is only a band-aid


CONT.TABLE <- continous %>%
  dplyr::filter(q.val < 0.01, abs(coef) > .1) %>%
  dplyr::group_by(pert_iname, pert_id, pert_plate, pert_dose, feature_type) %>%
  dplyr::arrange(coef) %>% dplyr::mutate(ix = 1:n()) %>%
  dplyr::arrange(-coef) %>% dplyr::mutate(ix = pmin(ix,1:n())) %>%
  dplyr::filter(ix < 4) %>%
  dplyr::arrange(coef) %>%
  dplyr::mutate(feature = paste0(word(feature,2,-1,sep = fixed("_"))," (",round(coef,2), ")")) %>%
  dplyr::summarise(feats = paste0(feature, collapse = ", ")) %>%
  dplyr::ungroup() %>%
  tidyr::pivot_wider(names_from = "feature_type",
                     values_from = "feats") %>%
  dplyr::ungroup() %>%
  dplyr::mutate(pert_dose = ifelse(pert_dose %in% c("log2.auc", "log2.ic50"),
                                   pert_dose, as.character(as.numeric(pert_dose))))

DISC.TABLE <- discrete %>%
  dplyr::filter(q.value < 0.01, abs(effect_size) > .1)  %>%
  dplyr::group_by(pert_iname, pert_id, pert_plate, pert_dose, feature_type) %>%
  dplyr::arrange(effect_size) %>% dplyr::mutate(ix = 1:n()) %>%
  dplyr::arrange(-effect_size) %>% dplyr::mutate(ix = pmin(ix,1:n())) %>%
  dplyr::filter(ix < 4) %>%
  dplyr::arrange(effect_size) %>%
  dplyr::mutate(feature = paste0(word(feature,2,-1,sep = fixed("_"))," (",round(effect_size,2), ")")) %>%
  dplyr::summarise(feats = paste0(feature, collapse = ", ")) %>%
  dplyr::ungroup() %>%
  tidyr::pivot_wider(names_from = "feature_type",
                     values_from = "feats") %>%
  dplyr::ungroup() %>%
  dplyr::mutate(pert_dose = ifelse(pert_dose %in% c("log2.auc", "log2.ic50"),
                                   pert_dose, as.character(as.numeric(pert_dose))))


BIOMARKER.TABLE <- RF.TABLE %>%
  dplyr::full_join(CONT.TABLE) %>%
  dplyr::full_join(DISC.TABLE)

# Next create summary statistics -----
LFC.TABLE <- lfc %>%
  dplyr::group_by(x_project_id, screen, pert_iname, pert_id, pert_plate, pert_dose,
                  replicate, ccle_name) %>%
  dplyr::summarise(LFC_cb = median(LFC_cb, na.rm = T)) %>%
  tidyr::pivot_wider(names_from = "replicate", values_from = "LFC_cb") %>%
  dplyr::rowwise() %>%
  dplyr::mutate(X = median(X1, X2, X3, na.rm = T)) %>%
  dplyr::group_by(x_project_id, screen, pert_iname, pert_id, pert_plate, pert_dose) %>%
  dplyr::summarise(
    #r1 = cor(X1,X2, use = "p"),
    #r2 = cor(X1,X3, use = "p"),
    #r3 = cor(X2, X3, use = "p"),
    BimodalityCoefficient = bimodality_coefficient(X[is.finite(X)]),
    CellLinesKilled = sum(X < log2(.3), na.rm = T)) %>%
  dplyr::rowwise() %>%
  #dplyr::mutate(AverageRepCor = mean(c(r1,r2,r3), na.rm = T)) %>%
  #dplyr::select(-r1, -r2, -r3) %>%
  dplyr::ungroup() %>%
  dplyr::mutate(pert_dose = as.character(pert_dose))



# Join and write to csv ----

LFC.TABLE %>%
  dplyr::full_join(BIOMARKER.TABLE) %>%
  dplyr::group_by(pert_id, pert_iname, pert_plate) %>%
  dplyr::mutate(BimodalityCoefficient = ifelse(pert_dose %in% c("log2.auc", "log2.ic50"),
                                               mean(BimodalityCoefficient, na.rm = T), BimodalityCoefficient),
                #AverageRepCor = ifelse(pert_dose %in% c("log2.auc", "log2.ic50"),
                #                               mean(AverageRepCor, na.rm = T), AverageRepCor),
                CellLinesKilled = ifelse(pert_dose %in% c("log2.auc", "log2.ic50"),
                                       mean(CellLinesKilled, na.rm = T), CellLinesKilled),
                x_project_id = ifelse(pert_dose %in% c("log2.auc", "log2.ic50"),
                                      x_project_id[!is.na(x_project_id)][1], x_project_id),
                screen = ifelse(pert_dose %in% c("log2.auc", "log2.ic50"),
                                         screen[!is.na(screen)][1], screen)) %>%
  dplyr::ungroup() %>%
  write_csv(paste0(out_dir, "/compound_summary_metrics.csv"))



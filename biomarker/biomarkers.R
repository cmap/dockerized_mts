# Script to run biomarker analysis on MTS data
# creates continuous associations, discrete associations, RF table, model table

# import necessary libraries and functions
suppressMessages(source("./src/biomarker_functions.R"))

#---- Read arguments ----

parser <- ArgumentParser()
# specify our desired options
parser$add_argument("-b", "--base_dir", default="", help="Input directory.")
parser$add_argument("-o", "--out", default=getwd(), help = "Output directory. Default is working directory.")
parser$add_argument("-d", "--biomarker_dir", default="/Users/shiker/Documents/archive/2024-Q2_formatted",
     help="Directory containing biomarker files.") # directory changed to local directory 
parser$add_argument("-f", "--biomarker_file", default=NULL, help="Name of biomarker file. Optional")
parser$add_argument("-q", "--qc", default=NULL, help = "Path to QC file to be used as confounders")

# get command line options, if help option encountered print help and exit
args <- parser$parse_args()

base_dir <- '/Users/shiker/Documents/trouble_shoot/mts021/MTS021_NATHANAEL_GRAY/PMTS056/BRD-U00116474'
out_dir <- '/Users/shiker/Documents/archive/2024-Q2_report_test/PMTS056/BRD-U00116474'
biomarker_dir <- args$biomarker_dir
biomarker_file <- args$biomarker_file
qc_path <- args$qc

# data names/types for loading from taiga
rf_data <- c("x-all", "x-ccle")
discrete_data <- c("lin", "mut")
# removing MET and miRNA and adding gdsc_prot and gse 
linear_data <- c("ge", "xpr", "cna", "rep", "prot", "shrna", "rppa", "gdsc_prot", "gse")
linear_names <- c("GE", "XPR", "CNA",  "REP", "PROT_BROAD", "RPPA", "shRNA", "PROT_GDSC", "GSE")

if (!is.null(biomarker_file) && !biomarker_file %in% c(rf_data, discrete_data, linear_data)) {
  stop("Unknown biomarker file. Please try again.")
}

# make output directory
if (!dir.exists(out_dir)) dir.create(out_dir, recursive = T)

#---- LOAD THE DATA ----
drc_path <- list.files(base_dir, pattern = "DRC_TABLE.csv", full.names = T)
lfc_path <- list.files(base_dir, pattern = "LEVEL5_LFC_.*\\.csv$", full.names = T)

# read dose-response if it's there
if (length(drc_path == 1)) {
  DRC <- data.table::fread(drc_path) %>%
    dplyr::distinct(across(any_of(c("ccle_name", "culture", "pool_id", "varied_id", "varied_iname", "auc", "log2.ic50", "max_dose",
                                    "added_compounds", "added_ids", "added_doses", "pert_time", "pert_plate")))) %>%
    dplyr::group_by(across(any_of(c("varied_id", "varied_iname", "max_dose", "pert_time", "pert_plate",
                                    "added_compounds", "added_ids", "added_doses")))) %>%
    dplyr::mutate(n_ic50 = sum(is.finite(log2.ic50))) %>%
    dplyr::ungroup() %>%
    dplyr::mutate(log2.ic50 = ifelse((is.finite(auc) & !is.finite(log2.ic50)) & n_ic50 >= 10,
                                     log2(3 * max_dose), log2.ic50),
                  log2.auc = log2(auc)) %>%
    dplyr::select(-n_ic50, -max_dose) %>%
    dplyr::select(-auc) %>%
    tidyr::pivot_longer(cols = c("log2.auc", "log2.ic50"),
                        names_to = "pert_dose", values_to = "response") %>%
    dplyr::mutate(pert_dose = as.character(pert_dose),pert_time = as.character(pert_time)) %>%
    dplyr::filter(is.finite(response)) %>%
    dplyr::rename(pert_iname = varied_iname, pert_id = varied_id)
} else {
  print("No DRC table found. Continuing with LFC only")
  DRC <- tibble()
}

# always expect LFC table
if (length(lfc_path) == 1) {
  LFC <- data.table::fread(lfc_path) %>%
    dplyr::distinct(across(any_of(c("ccle_name", "culture", "pool_id", "pert_id", "pert_time",
                                    "pert_iname", "pert_dose", "pert_plate", "LFC", "LFC_cb")))) %>%
    dplyr::mutate(pert_dose = as.character(pert_dose),pert_time = as.character(pert_time))

  if ("LFC_cb" %in% colnames(LFC)) {
    LFC %<>%
      dplyr::rename(response = LFC_cb)
  } else {
    LFC %<>%
      dplyr::rename(response = LFC)
  }

} else {
  stop(paste("There are", length(lfc_path), "LFC files in the supplied directory. Please try again with 1."),
       call. = FALSE)
}

# TO DO: update with new pipeline columns
# read QC table if passed
if (!is.null(qc_path) && file_test("-f", qc_path)) {
  qc_table <- data.table::fread(qc_path) %>%
    dplyr::filter(pass,
                  pert_plate %in% (LFC$pert_plate %>% unique())) %>%
    dplyr::group_by(ccle_name) %>%
    dplyr::summarise(dr = median(dr), ssmd = median(ssmd), nnmd = median(nnmd),
                     .groups = "drop") %>%
    column_to_rownames("ccle_name") %>%
    as.matrix()
} else {
  print("No SSMD table supplied or readable defaulting to no confounders")
  qc_table <- NULL
}

# combine into large table
all_Y <- dplyr::bind_rows(DRC, LFC)

# SKIP BECAUSE REP HAS COMPOUND NAMES NOT BRDS 
# if (is.null(biomarker_file) || biomarker_file == "rep") {
#   rep_meta <- data.table::fread(paste0(biomarker_dir, "/rep_info.csv")) %>%
#     dplyr::select(column_name, name) %>%
#     dplyr::mutate(column_name = paste0("REP_", column_name))
# }


# SKIP BECAUSE WE DON'T USE LIN_PCA 
# get lineage principal components to use as confounder
# if (is.null(biomarker_file) || biomarker_file == "ge") {
#   LIN_PCs <- data.table::fread(paste0(biomarker_dir, "/linPCA.csv")) %>%
#     column_to_rownames("V1") %>% as.matrix()
#   confounder_overlap <- intersect(rownames(LIN_PCs), rownames(qc_table))
#   if (!is.null(qc_table)) LIN_PCs <- cbind(LIN_PCs[confounder_overlap, ], qc_table[confounder_overlap, ])
# }

runs <- all_Y %>%
  dplyr::distinct(across(any_of(c("pert_iname", "pert_id", "pert_time", "pert_dose", "pert_plate",
                                  "added_compounds", "added_ids", "added_doses"))))

#---- LOOP THORUGH DATASETS AND DOSES ----

# linear associations
linear_table <- list(); ix <- 1
for(feat in 1:length(linear_data)) {

  # if specified only process for given file
  if (!is.null(biomarker_file) && linear_data[feat] != biomarker_file) {
    next
  }

  print(linear_data[feat])

  # load feature set
  X <- data.table::fread(paste0(biomarker_dir, "/", linear_data[feat], ".csv")) %>%
    column_to_rownames("V1") %>% as.matrix()

  # for each perturbation get results
  for(i in 1:nrow(runs)) {
    # filter down to current dose (run)
    run <- runs[i,]
    Y <- all_Y %>%
      dplyr::inner_join(run)
    y <- Y$response; names(y) <- Y$ccle_name
    y <- y[is.finite(y)]

    # get overlapping data
    overlap <- dplyr::intersect(rownames(X), names(y))
    y <- y[overlap]
    if (!is.null(qc_table)) {
      W <- qc_table[overlap, ]
    } else {
      W <- NULL
    }

    # if insufficient data, skip
    if (length(y) < 10 | min(y) == max(y)) {
      next
    } else {
      # calculate correlations
      res.lin <- cdsrmodels::lin_associations(X[overlap,], y, W = W)
      res.cor <- res.lin$res.table %>%
        cbind(., rho=res.lin$rho[rownames(.),], q.val=res.lin$q.val[rownames(.),]) %>%
        tibble::as_tibble() %>%
        dplyr::rename(feature = ind.var, coef = rho) %>%
        dplyr::arrange(q.val) %>%
        dplyr::mutate(rank = 1:n(),
                      feature_type = linear_names[feat]) %>%
        dplyr::filter(rank <= 1000 | q.val < 0.1) %>%
        dplyr::bind_cols(run)

      # for repurposing replace metadata
      if (linear_data[feat] == "rep") {
        res.cor %<>%
          # dplyr::left_join(rep_meta, by = c("feature" = "column_name")) %>%
          # dplyr::select(-feature) %>%
          # dplyr::rename(feature = name) %>%
          dplyr::mutate(feature = paste("REP", feature, sep = "_"))
      }

      # append to output tables
      linear_table[[ix]] <- res.cor; ix <- ix + 1
    }
  }

  # gene expression with lineage as confounder - not currently computed in biomarker analysis 
  # if (linear_data[feat] == "ge") {
  # 
  #   # for each perturbation get results
  #   for(i in 1:nrow(runs)) {
  #     # filter down to current dose (run)
  #     run <- runs[i,]
  #     Y <- all_Y %>%
  #       dplyr::inner_join(run)
  #     y <- Y$response; names(y) <- Y$ccle_name
  #     y <- y[is.finite(y)]
  # 
  #     overlap <- dplyr::intersect(rownames(X), names(y)) %>%
  #       dplyr::intersect(., rownames(LIN_PCs))
  #     y <- y[overlap]
  # 
  #     if (length(y) < 10 | min(y) == max(y)) {
  #       next
  #     } else {
  #       # check that there are unique confounders
  #       if (all(apply(LIN_PCs[overlap,], 2, function(x) length(unique(x)) == 1))) {
  #         next
  #       } else {
  #         res.lin <- cdsrmodels::lin_associations(X[overlap,], y, W = LIN_PCs[overlap,])
  #         res.cor <- res.lin$res.table %>%
  #           cbind(., rho=res.lin$rho[rownames(.),], q.val=res.lin$q.val[rownames(.),]) %>%
  #           tibble::as_tibble() %>%
  #           dplyr::rename(feature = ind.var, coef = rho) %>%
  #           dplyr::arrange(q.val) %>%
  #           dplyr::mutate(rank = 1:n(),
  #                         feature_type = "GE_noLIN") %>%
  #           dplyr::filter(rank <= 1000 | q.val < 0.1) %>%
  #           dplyr::bind_cols(run)
  # 
  #         linear_table[[ix]] <- res.cor; ix <- ix + 1
  #       }
  #     }
  #   }
  # }
}
if (length(linear_table) > 0) {
  linear_table %<>% dplyr::bind_rows()
  file_suffix <- if (is.null(biomarker_file)) "" else paste0("_", biomarker_file)
  file_name <- paste0(out_dir, "/continuous_associations", file_suffix, ".csv")
  write.csv(linear_table, file_name, row.names=FALSE)
}

# repeat for discrete t-test
discrete_table <- list(); ix <- 1
for(feat in 1:length(discrete_data)) {
  # if specified only process for given file
  if (!is.null(biomarker_file) && discrete_data[feat] != biomarker_file) {
    next
  }

  print(discrete_data[feat])

  # load feature set
  X <- data.table::fread(paste0(biomarker_dir, "/", discrete_data[feat], ".csv")) %>%
    column_to_rownames("V1") %>% as.matrix()

  for(i in 1:nrow(runs)) {
    # filter down to current dose (run)
    run <- runs[i,]
    Y <- all_Y %>%
      dplyr::inner_join(run)
    y <- Y$response; names(y) <- Y$ccle_name
    y <- y[is.finite(y)]

    # get overlapping data
    overlap <- dplyr::intersect(rownames(X), names(y))
    y <- y[overlap]
    if (!is.null(qc_table)) {
      W <- qc_table[overlap, ]
    } else {
      W <- NULL
    }

    if (length(y) < 10 | min(y) == max(y)) {
      next
    } else {
      res.disc <- cdsrmodels::discrete_test(X[overlap,], y, W = W) %>%
        dplyr::mutate(feature_type = toupper(discrete_data[feat]))

      res.disc %<>%
        dplyr::bind_cols(run)

      # only keep top 500 mutations
      if (discrete_data[feat] == "mut" & nrow(res.disc) > 0) {
        res.disc %<>%
          dplyr::arrange(q.value) %>%
          dplyr::mutate(rank = 1:n()) %>%
          dplyr::filter(rank <= 500) %>%
          dplyr::select(-rank)
      }

      discrete_table[[ix]] <- res.disc; ix <- ix + 1
    }
  }
}
if (length(discrete_table) > 0) {
  discrete_table %<>% dplyr::bind_rows()
  file_suffix <- if (is.null(biomarker_file)) "" else paste0("_", biomarker_file)
  file_name <- paste0(out_dir, "/discrete_associations", file_suffix, ".csv")
  write.csv(discrete_table, file_name, row.names=FALSE)
}

# repeat for random forest
random_forest_table <- list(); model_table <- list(); ix <- 1
for(feat in 1:length(rf_data)) {
  # if specified only process for given file
  if (!is.null(biomarker_file) && rf_data[feat] != biomarker_file) {
    next
  }
  print(rf_data[feat])

  # load feature set
  X <- data.table::fread(paste0(biomarker_dir, "/", rf_data[feat], ".csv")) %>%
    column_to_rownames("V1") %>% as.matrix()

  model <- word(rf_data[feat], 2, sep = fixed("-"))

  for (i in 1:nrow(runs)) {
    run <- runs[i,]
    Y <- all_Y %>%
      dplyr::inner_join(run)
    y <- Y$response; names(y) <- Y$ccle_name
    y <- y[is.finite(y)]

    # get overlapping data
    overlap <- dplyr::intersect(rownames(X), names(y))
    y <- y[overlap]
    if (!is.null(qc_table)) {
      W <- qc_table[overlap, ]
    } else {
      W <- NULL
    }

    if (length(y) < 10 | min(y) == max(y)) {
      next
    } else {
      res.rf <- cdsrmodels::random_forest(X[overlap,], y, W = W)
      res.model <- res.rf$model_table %>%
        dplyr::distinct(MSE, MSE.se, R2, PearsonScore) %>%
        dplyr::mutate(model = model) %>%
        dplyr::bind_cols(run)
      res.features <- res.rf$model_table %>%
        dplyr::distinct(feature, RF.imp.mean, RF.imp.sd, RF.imp.stability, rank) %>%
        dplyr::mutate(model = model) %>%
        dplyr::bind_cols(run)
      random_forest_table[[ix]] <- res.features; model_table[[ix]] <- res.model
      ix <- ix + 1
    }
  }
}
if (length(random_forest_table) > 0) {
  random_forest_table %<>% dplyr::bind_rows(); model_table %<>% dplyr::bind_rows()
  file_suffix <- if (is.null(biomarker_file)) "" else paste0("_", biomarker_file)
  model_name <- paste0(out_dir, "/model_table", file_suffix, ".csv")
  rf_name <- paste0(out_dir, "/RF_table", file_suffix, ".csv")
  write.csv(random_forest_table, rf_name, row.names=FALSE)
  write.csv(model_table, model_name, row.names=FALSE)
}

# Script to run biomarker analysis on MTS data
# creates continuous associations, discrete associations, RF table, model table

# import necessary libraries and functions
suppressMessages(source("./src/biomarker_functions.R"))

#---- Read arguments ----

parser <- ArgumentParser()
# specify our desired options
parser$add_argument("-b", "--base_dir", default="", help="Input directory.")
parser$add_argument("-o", "--out", default=getwd(), help = "Output directory. Default is working directory.")
parser$add_argument("-d", "--biomarker_dir", default="https://s3.amazonaws.com/biomarker.clue.io/.cache", help="Directory containing biomarker files.")
parser$add_argument("-q", "--qc", default="NA", help = "Path to QC file to be used as confounders")

# get command line options, if help option encountered print help and exit
args <- parser$parse_args()

base_dir <- args$base_dir
out_dir <- args$out
biomarker_dir <- args$biomarker_dir
qc_path <- args$qc


# make output directory
if (!dir.exists(out_dir)) dir.create(out_dir, recursive = T)

#---- LOAD THE DATA ----
drc_path <- list.files(base_dir, pattern = "DRC_TABLE.csv", full.names = T)
lfc_path <- list.files(base_dir, pattern = "LEVEL5_LFC", full.names = T)

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
    dplyr::filter(is.finite(response)) %>%
    dplyr::rename(pert_iname = varied_iname, pert_id = varied_id)
} else {
  print("No DRC table found. Continuing with LFC only")
  DRC <- tibble()
}

# always expect LFC table
if (length(lfc_path) == 1) {
  LFC <- data.table::fread(lfc_path) %>%
    dplyr::distinct(across(any_of(c("ccle_name", "culture", "pool_id", "pert_id",
                                    "pert_iname", "pert_dose", "pert_plate", "LFC", "LFC.cb"))))
  
  if ("LFC.cb" %in% colnames(LFC)) {
    LFC %<>%
      dplyr::rename(response = LFC.cb) %>%
      dplyr::select(-LFC)
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
if (qc_path != "NA" & file_test("-f", qc_path)) {
  qc_table <- data.table::fread(qc_path) %>%
    dplyr::filter(pass,
                  compound_plate %in% (LFC$compound_plate %>% unique())) %>%
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

# data names/types for loading from taiga
rf_data <- c("x-all", "x-ccle")
discrete_data <- c("lin", "mut")
linear_data <- c("ge", "xpr", "cna", "met", "mirna", "rep", "prot", "shrna")
linear_names <- c("GE", "XPR", "CNA", "MET", "miRNA", "REP", "PROT", "shRNA")
rep_meta <- data.table::fread(paste0(biomarker_dir, "/rep_info.csv")) %>%
  dplyr::select(column_name, name) %>%
  dplyr::mutate(column_name = paste0("REP_", column_name))

# get lineage principal components to use as confounder
LIN_PCs <- data.table::fread(paste0(biomarker_dir, "/linPCA.csv"))
confounder_overlap <- intersect(rownames(LIN_PCs), rownames(qc_table))
if (!is.null(qc_table)) LIN_PCs <- cbind(LIN_PCs[confounder_overlap, ], qc_table[confounder_overlap, ])

runs <- all_Y %>%
  dplyr::distinct(across(any_of(c("pert_iname", "pert_id", "pert_time", "pert_dose", "pert_plate",
                                  "added_compounds", "added_ids", "added_doses"))))

#---- LOOP THORUGH DATASETS AND DOSES ----

# linear associations
linear_table <- list(); ix <- 1
for(feat in 1:length(linear_data)) {
  
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
        dplyr::mutate(rank = 1:n()) %>%
        dplyr::filter(rank <= 1000 | q.val < 0.1) %>%
        dplyr::bind_cols(run)
      
      # for repurposing replace metadata
      if (linear_data[feat] == "rep") {
        res.cor %<>%
          dplyr::left_join(rep_meta, by = c("feature" = "column_name")) %>%
          dplyr::select(-feature) %>%
          dplyr::rename(feature = name) %>%
          dplyr::mutate(feature = paste("REP", feature, sep = "_"))
      }
      
      # append to output tables
      linear_table[[ix]] <- res.cor; ix <- ix + 1
    }
  }
  
  # gene expression with lineage as confounder
  if (linear_data[feat] == "ge") {
    
    # for each perturbation get results
    for(i in 1:nrow(runs)) {
      # filter down to current dose (run)
      run <- runs[i,]
      Y <- all_Y %>%
        dplyr::inner_join(run)
      y <- Y$response; names(y) <- Y$ccle_name
      y <- y[is.finite(y)]
      
      overlap <- dplyr::intersect(rownames(X), names(y)) %>%
        dplyr::intersect(., rownames(LIN_PCs))
      y <- y[overlap]
      
      if (length(y) < 10 | min(y) == max(y)) {
        next
      } else {
        # check that there are unique confounders
        if (all(apply(LIN_PCs[overlap,], 2, function(x) length(unique(x)) == 1))) {
          next
        } else {
          res.lin <- cdsrmodels::lin_associations(X[overlap,], y, W = LIN_PCs[overlap,])
          res.cor <- res.lin$res.table %>%
            cbind(., rho=res.lin$rho[rownames(.),], q.val=res.lin$q.val[rownames(.),]) %>%
            tibble::as_tibble() %>%
            dplyr::rename(feature = ind.var, coef = rho) %>%
            dplyr::arrange(q.val) %>%
            dplyr::mutate(rank = 1:n()) %>%
            dplyr::filter(rank <= 1000 | q.val < 0.1) %>%
            dplyr::bind_cols(run)
          
          linear_table[[ix]] <- res.cor; ix <- ix + 1
        }
      }
    }
  }
}
linear_table %<>% dplyr::bind_rows()
readr::write_csv(linear_table, paste0(output_dir, "/continuous_associations.csv"))


# TODO: fix after this mark
# repeat for discrete t-test
discrete_table <- list(); ix <- 1
for(feat in 1:length(discrete_data)) {
  X <- taigr::load.from.taiga(data.name="biomarker-features-5baa", data.version=ver,
                              data.file=discrete_data[feat], quiet=T)
  for(i in 1:nrow(runs)) {
    run <- runs[i,]
    Y <- all_Y %>%
      dplyr::inner_join(run, by = c("pert_time", "pert_name", "pert_mfc_id", "dose"))
    y <- Y$response; names(y) <- Y$ccle_name
    y <- y[is.finite(y)]
    
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
      res.disc <- cdsrmodels::discrete_test(X[overlap,], y, W = W)
      
      res.disc %<>%
        dplyr::mutate(pert_mfc_id = run$pert_mfc_id,
                      pert_name = run$pert_name,
                      pert_time = run$pert_time,
                      dose = run$dose,
                      feature_type = toupper(discrete_data[feat]))
      
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
discrete_table %<>% dplyr::bind_rows()
readr::write_csv(discrete_table, paste0(output_dir, "/discrete_associations.csv"))

# repeat for random forest
random_forest_table <- list(); model_table <- list(); ix <- 1

for(feat in 1:length(rf_data)) {
  
  X <- taigr::load.from.taiga(data.name="biomarker-features-5baa", data.version=ver,
                              data.file=rf_data[feat], quiet=T)
  model <- word(rf_data[feat], 2, sep = fixed("-"))
  
  for (i in 1:nrow(runs)) {
    run <- runs[i,]
    Y <- all_Y %>%
      dplyr::inner_join(run, by = c("pert_time", "pert_name", "pert_mfc_id", "dose"))
    y <- Y$response; names(y) <- Y$ccle_name
    y <- y[is.finite(y)]
    
    overlap <- dplyr::intersect(rownames(X), names(y))
    y <- y[overlap]
    
    if (!is.null(qc_table)) {
      W <- qc_table[overlap, ]
      colnames(W) <- paste0("CONF_", colnames(W))
    } else {
      W <- NULL
    }
    
    if (length(y) < 10 | min(y) == max(y)) {
      next
    } else {
      res.rf <- cdsrmodels::random_forest(X[overlap,], y, W = W)
      res.model <- res.rf$model_table %>%
        dplyr::distinct(MSE, MSE.se, R2, PearsonScore) %>%
        dplyr::mutate(model = model,
                      pert_mfc_id = run$pert_mfc_id,
                      pert_name = run$pert_name,
                      pert_time = run$pert_time,
                      dose = run$dose)
      res.features <- res.rf$model_table %>%
        dplyr::distinct(feature, RF.imp.mean, RF.imp.sd, RF.imp.stability, rank) %>%
        dplyr::mutate(model = model,
                      pert_mfc_id = run$pert_mfc_id,
                      pert_name = run$pert_name,
                      pert_time = run$pert_time,
                      dose = run$dose)
      random_forest_table[[ix]] <- res.features; model_table[[ix]] <- res.model
      ix <- ix + 1
    }
  }
}
random_forest_table %<>% dplyr::bind_rows(); model_table %<>% dplyr::bind_rows()
readr::write_csv(random_forest_table, paste0(output_dir, "/RF_table.csv"))
readr::write_csv(model_table, paste0(output_dir, "/Model_table.csv"))

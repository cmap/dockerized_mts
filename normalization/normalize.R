# Script to run the initial processing step of the MTS pipeline
# creates logMFI and logMFI_NORMALIZED

# import necessary libraries and functions
suppressMessages(source("./src/normalization_functions.R"))

#---- Read arguments ----

parser <- ArgumentParser()
# specify our desired options
parser$add_argument("-b", "--base_dir", default="", help="Input Directory")
parser$add_argument("-o", "--out", default=getwd(), help = "Output path. Default is working directory")
parser$add_argument("-a", "--assay", default="", help="Assay string (e.g. PR500)")
parser$add_argument("-n", "--name", default="", help="Build name. Default is none")
parser$add_argument("-c", "--api_call", default=FALSE, help="Get build metadata from clue API")
parser$add_argument("-r", "--rep_corr_filter", default=TRUE, help="Remove poorly correlated replicates. Do not use with in-plate replicates")

# get command line options, if help option encountered print help and exit
args <- parser$parse_args()

base_dir <- args$base_dir
out_dir <- args$out
assay <- args$assay
build_name <- args$name
api_call <- args$api_call
rep_corr <- args$rep_corr_filter

cat("API_CALL: ", {api_call}, "\n")

if (!dir.exists(out_dir)) {dir.create(out_dir, recursive = T)}

# paths to data (make sure directory of data has these files)
# TODO: add var for count path
path_count <- list.files(base_dir, pattern = "*_LEVEL2_COUNT*", full.names=T)
path_data <- list.files(base_dir, pattern =  "*_LEVEL2_MFI*", full.names = T)
path_cell_info <- list.files(base_dir, pattern = "*_cell_info*", full.names = T)
path_inst_info <- list.files(base_dir, pattern = "*_inst_info*", full.names = T)

# Reorganization files
path_reorg_mapping <- list.files("/data/reorg", pattern = "*reorg_map*", full.names = T)
path_reorg_subset <- list.files("/data/reorg", pattern = "*reorg_subset*", full.names = T)

#---- Load the data ----

# read in logMFI data
print(path_data)
count_matrix <- read_hdf5(path_count)
rownames(count_matrix) <- paste0(rownames(count_matrix), "_", assay)
raw_matrix <- read_hdf5(path_data)
rownames(raw_matrix) <- paste0(rownames(raw_matrix), "_", assay)

# read in cell line info
cell_info <- data.table::fread(path_cell_info, colClasses = "character") %>%
  dplyr::distinct(rid, ccle_name, pool_id, barcode_id) %>%
  dplyr::mutate(culture = assay) %>%
  dplyr::mutate(rid = paste0(rid, "_", assay)) %>%
  dplyr::mutate(pool_id = ifelse(pool_id == "" | pool_id == -666,
                                 "CTLBC", pool_id))


# read in inst_info
inst_info <- data.table::fread(path_inst_info, colClasses = "character")

# split out base plate
base_day <- data.table::fread(path_inst_info)
base_day <- extract_baseplate(base_day, base_string="BASE", inst_column = "prism_replicate")

# ensure unique profile IDs
raw_matrix <- raw_matrix[, inst_info$profile_id %>% unique()]

# melt matrix into data tables and join with inst and cell info
count_table <- build_count_table(count_matrix)
master_logMFI <- build_master_logMFI(raw_matrix, inst_info, cell_info, count_table)

#------Count filtering-------
print("Filtering and recording low counts wells")
# filter low count wells
filter_results <- filter_lowcounts(master_logMFI)
master_logMFI <- filter_results$filtered_df

# write record of removed instances and wells
removed_instances_cnt <- filter_results$removed_instances
if (length(removed_instances_cnt) > 0) {
  #cat(paste("Removing instance", removed_instances_cnt, "\n"))
  # Write file of removed ccle_names
  writeLines(removed_instances_cnt, paste0(out_dir, "/", build_name, "_removed_instances_count.txt"))
}


removed_pert_wells_cnt <- filter_results$removed_wells
if (length(removed_pert_wells_cnt) > 0) {
  # Write file of removed ccle_names
  write.csv(removed_pert_wells_cnt, paste0(out_dir, "/", build_name, "_removed_wells_count.csv"))
}

#--------Manual instance removal-----------
# get build metadata if call can be made to clue API
if (api_call) {
  print("Making call to clue API....")
  # Get url and credentials
  endpoint_url <- Sys.getenv("API_URL")
  cat("Endpoint URL: ", {endpoint_url}, "\n")
  user_key <- Sys.getenv("API_KEY")

  where_clause <- list(name = build_name)
  request_url <- make_request_url_filter(endpoint_url, where_clause)
  build_data <- get_data_from_db(endpoint_url, user_key, where_clause)

  # Add cellset information
  cell_set <- build_data$assay_type[1]
  master_logMFI$cell_set <- cell_set

  # Remove BCIDs if necessary
  exclude_bcids <- build_data$exclude_bcids[[1]]
  if (!is.null(exclude_bcids)) {
    # Check if all exclude_bcids are in cell_info
    if (!all(exclude_bcids %in% cell_info$barcode_id)) {
      non_existant_bcids <- exclude_bcids[!exclude_bcids %in% cell_info$barcode_id]
      msg = paste("There are barcode_ids requested for removal that do not exist in the data: ",
      paste(non_existant_bcids, collapse="\n"), sep="\n")
      stop(msg)
    }

    # Find the ccle_names corresponding to the barcode_ids in cell_info
    matching_ccle_names <- cell_info$ccle_name[cell_info$barcode_id %in% exclude_bcids]

    cat("Removing ccle_names corresponding to barcodes: ", paste(exclude_bcids, collapse=", "), "\n")
    
    if (length(matching_ccle_names) > 0) {
      # Write file of removed ccle_names
      writeLines(matching_ccle_names, paste0(out_dir, "/", build_name, "_removed_ccle_names.txt"))
      
      # Filter out the rows with these ccle_names from master_logMFI
      master_logMFI <- dplyr::filter(master_logMFI, !(ccle_name %in% matching_ccle_names))
    }
  }


  # Remove instances if necessary
  remove_instances <- build_data$remove_instances[[1]]
  if (!is.null(remove_instances)) {
    if (!all(remove_instances %in% master_logMFI$instance_id)) {
      # check that all of the entries exist
      unmatched_instances <- remove_instances[!remove_instances %in% master_logMFI$instance_id]
      msg <- paste("There are instance_ids requested for removal that do not exist in the data: ",
                               paste(unmatched_instances, collapse="\n"), sep="\n")
      stop(msg)
    }

    # Extract the instance_ids to remove
    removed_instance_ids <- master_logMFI$instance_id[master_logMFI$instance_id %in% remove_instances]
    msg <- paste("Removing instance: ", paste(removed_instance_ids, collapse="\n"), sep="\n")
    cat(msg, "\n")

    if (length(removed_instance_ids) > 0) {
      # Write the removed instance_ids to a text file
      writeLines(removed_instance_ids, paste0(out_dir, "/", build_name, "_removed_instance_ids.txt"))
      # Filter out the instances from master_logMFI
      master_logMFI %<>% dplyr::filter(!(instance_id %in% remove_instances))
      #master_logMFI <- master_logMFI[!master_logMFI$instance_id %in% remove_instances, ]
    } else {
        print("No instance_ids matched the criteria for removal.")
    }
  }
}

# create barcode tables
barcodes <- master_logMFI %>%
  dplyr::filter(pool_id == "CTLBC")

if (nrow(barcodes) == 0) stop("No control barcodes detected. Unable to normalize")

# filter base plates
logMFI_base <- master_logMFI %>%
  dplyr::filter(str_detect(prism_replicate, "BASE"))
master_logMFI %<>%
  dplyr::filter(!str_detect(prism_replicate, "BASE"))

#---- Normalize ----

# compute control barcode median of medians for normalization
logMFI_control_medians <- control_medians(master_logMFI %>%
                                            dplyr::filter(is.finite(logMFI),
                                                          logMFI != 0))

# fit curve to controls and predict test conditions
logMFI_normalized <- normalize(logMFI_control_medians, barcodes, nrow(cell_info) / 2)

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
    dplyr::filter(is.finite(logMFI), logMFI != 0) %>%
    dplyr::left_join(logMFI_profile) %>%
    normalize_base(., barcodes, nrow(cell_info) / 2)
} else {
  base_normalized <- tibble()
}

# join with other info (LMFI is normalized, logMFI is not)
logMFI_normalized %<>%
  dplyr::left_join(master_logMFI)

#---- Reorganization ----
cat("Reorganizing data based on mappings...\n")

# Save original dimensions of logMFI_normalized before reorganization
original_dim <- dim(logMFI_normalized)

# Read data and reorganize if reorganization files exist
if (length(path_reorg_mapping) > 0 && length(path_reorg_subset) > 0) {
  reorg_mapping <- data.table::fread(path_reorg_mapping)
  reorg_subset <- data.table::fread(path_reorg_subset)

  # Reorganize data
  logMFI_normalized <- reorg_mfi(mfi = logMFI_normalized,
                                 reorg_mapping = reorg_mapping,
                                 reorg_subset = reorg_subset)

  # Ensure new dimensions are the same as original dimensions
    if (dim(logMFI_normalized)[1] != original_dim[1] || dim(logMFI_normalized)[2] != original_dim[2]) {
        stop("Reorganization failed. Dimensions of reorganized data do not match original dimensions.")
    }
} else {
  # Fail if reorg files do not exist
  stop("No reorganization files found. Halting execution.")
}

#---- ID and filter low correlation pools if required ----

if (rep_corr) {
  # Calculate the delta between logMFI and median logMFI for each condition
  LMFI_delta <- calculate_deltas(logMFI_normalized)
  
  # Calculate pool-wise replicate correlations
  LMFI_corr <- calculate_replicate_correlations(LMFI_delta)
  
  # Get the median values
  LMFI_corr_median <- LMFI_corr %>%
    dplyr::filter(pool_id != 'CTLBC') %>%
    dplyr::group_by(pert_id, pert_iname, pert_dose, pert_plate, pool_id, prism_replicate,
                    replicate, pert_well) %>%
    dplyr::summarise(delta_LMFI_norm_median = median(delta_LMFI_norm),
                     LMFI_norm_corr = median(LMFI_norm_corr)) %>%
    dplyr::ungroup()
  
  # Annotate pass/fail with replicate correlation metrics and select failures
  LMFI_corr_remove <- annotate_rep_corr_pass(LMFI_corr_median) %>%
    dplyr::filter(pass_rc == FALSE)
  # Write failures to file for recordkeeping
  write.csv(LMFI_corr_remove, paste0(out_dir, "/", build_name, "_POOL_WELLS_REMOVED.csv"), row.names = FALSE)
  
  # Remove matching data from master logMFI_normalized table
  logMFI_normalized <- anti_join(logMFI_normalized, LMFI_corr_remove, 
                                 by = c("pert_id", "pert_iname", "pert_dose", 
                                        "pert_plate", "prism_replicate", 
                                        "pool_id", "replicate", "pert_well"))
}


#---- Write data ----
logMFI_normalized %>%
  dplyr::bind_rows(base_normalized) %>%
  dplyr::select(-rLMFI) %>%
  write.csv(., paste0(out_dir, "/", build_name, "_LEVEL3_LMFI.csv"), row.names=FALSE)

# compound key
write_key(logMFI_normalized, out_dir, build_name)

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

# get command line options, if help option encountered print help and exit
args <- parser$parse_args()

base_dir <- args$base_dir
out_dir <- args$out
assay <- args$assay
build_name <- args$name
api_call <- args$api_call

cat("API_CALL: ", {api_call}, "\n")

if (!dir.exists(out_dir)) {dir.create(out_dir, recursive = T)}

# paths to data (make sure directory of data has these files)
# TODO: add var for count path
path_count <- list.files(base_dir, pattern = "*_LEVEL2_COUNT*", full.names=T)
path_data <- list.files(base_dir, pattern =  "*_LEVEL2_MFI*", full.names = T)
path_cell_info <- list.files(base_dir, pattern = "*_cell_info*", full.names = T)
path_inst_info <- list.files(base_dir, pattern = "*_inst_info*", full.names = T)

#---- Load the data ----

# read in logMFI data
print(path_data)
count_matrix <- read_hdf5(path_count)
rownames(count_matrix) <- paste0(rownames(count_matrix), "_", assay)
raw_matrix <- read_hdf5(path_data)
rownames(raw_matrix) <- paste0(rownames(raw_matrix), "_", assay)

# read in cell line info
cell_info <- data.table::fread(path_cell_info, colClasses = "character") %>%
  dplyr::distinct(rid, ccle_name, pool_id) %>%
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
  if (!is.null(exclude_bcids)){
    # Extract the BCIDs to remove
    removed_bc_ids <- master_logMFI$barcode_id[master_logMFI$barcode_id %in% exclude_bcids]
    cat("Removing barcodes: ", {removed_bc_ids}, "\n")
    if (length(removed_bc_ids) > 0){
      # Write file of removed BCIDs
      writeLines(removed_bc_ids, paste0(out_dir, "/", build_name, "_removed_bcids.txt"))
      # Filter removed BCIDs from master_logMFI
      master_logMFI %<>% dplyr::filter(!(barcode_id %in% removed_bc_ids))
      }
    }

  # Remove instances if necessary
  remove_instances <- build_data$remove_instances[[1]]
  if (!is.null(remove_instances)) {
    if (!all(remove_instances %in% master_logMFI$instance_id)) {
      unmatched_instances <- remove_instances[!remove_instances %in% master_logMFI$instance_id]
      msg <- paste("There are instance_ids requested for removal that do not exist in the data: ",
                               paste(unmatched_instances, collapse="\n"), sep="\n")
      stop(msg)
    }

    # Extract the instance_ids to remove
    removed_instance_ids <- master_logMFI$instance_id[master_logMFI$instance_id %in% remove_instances]
    msg <- paste("Removing instances:", paste(removed_instance_ids, collapse="\n"), sep="\n")
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

#---- Write data ----
logMFI_normalized %>%
  dplyr::bind_rows(base_normalized) %>%
  dplyr::select(-rLMFI) %>%
  write.csv(., paste0(out_dir, "/", build_name, "_LEVEL3_LMFI.csv"), row.names=FALSE)

# compound key
write_key(logMFI_normalized, out_dir, build_name)

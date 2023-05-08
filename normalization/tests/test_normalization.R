library(testthat)
source("../src/normalization_functions.R")

two_base_dt <- data.table("prism_replicate" = c("BASE", "FOO", "BASE" )) 

missing_col <- data.table("not_prism_replicate" = c("BASE", "FOO", "BASE" )) 

test_that("base plate extracted", {
  expect_equal(nrow(extract_baseplate(two_base_dt)), 2)
})

test_that("base plate extracted", {
  expect_error(extract_baseplate(missing_col), regex="*Column `prism_replicate` not found*")
})

#happy case
instinfo = data.table::fread("./assets/test_instinfo.txt")
cellinfo = data.table::fread("./assets/test_cellinfo.txt")
raw_matrix = read_hdf5("./assets/test_LEVEL2_MFI_n10x10.gctx")
masterlogMFI = build_master_logMFI(raw_matrix = raw_matrix, inst_info=instinfo, cell_info = cellinfo)

ground_truth_masterlogMFI = data.table::fread("./assets/ground_truth_masterlogMFI.csv")
test_that("Annotating LogMFI matrix", {
  expect_equal(nrow(masterlogMFI),nrow(ground_truth_masterlogMFI)) #check that no rows were lost/melt was successful
  expect_equal(ncol(masterlogMFI),ncol(ground_truth_masterlogMFI)) #check that columns were added
})

# unhappy
# no profile_id column in instinfo
instinfo_noprofid = subset(instinfo, select=-c(profile_id))
test_that("Error if instinfo is missing `profile_id`", {
  expect_error(build_master_logMFI(raw_matrix = raw_matrix, inst_info=instinfo_noprofid, cell_info = cellinfo),
               regex="*`x` and `y` have no common variables*")
})

# no rid column in cellinfo
cellinfo_norid = subset(cellinfo, select=-c(rid))
test_that("Error if cellinfo is missing `rid`", {
  expect_error(build_master_logMFI(raw_matrix = raw_matrix, inst_info=instinfo, cell_info = cellinfo_norid),
               regex="*`x` and `y` have no common variables*")
})




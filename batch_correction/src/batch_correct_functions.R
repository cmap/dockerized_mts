# Helper functions for the initial processing step of the MTS pipeline

#---- Load Packages ----
library(tidyverse)
library(magrittr)
library(data.table)
library(sva)
library(readr)
library(stats)
library(reshape2)
library(argparse)

#---- Batch Correction ----
# corrects for pool effects using ComBat
apply_combat <- function(Y) {

  # create "condition" column to be used as "batches"
  df <- Y %>%
    dplyr::distinct(ccle_name, prism_replicate, LFC, culture, pool_id, pert_well) %>%
    tidyr::unite(cond, culture, pool_id, prism_replicate, sep = "::") %>%
    dplyr::filter(is.finite(LFC))

  # calculate means and sd's of each condition
  batch <- df$cond
  m <- rbind(df$LFC,
             rnorm(length(df$LFC),
                   mean =  mean(df$LFC, na.rm = TRUE),
                   sd = sd(df$LFC, na.rm = TRUE)))

  # use ComBat to align means and sd's of conditions
  combat <- sva::ComBat(dat = m, batch = batch) %>%
    t() %>%
    as.data.frame() %>%
    dplyr::mutate(ccle_name = df$ccle_name, cond = df$cond, pert_well = df$pert_well) %>%
    dplyr::rename(LFC_cb = V1) %>%
    dplyr::mutate(culture = stringr::word(cond, 1, sep = stringr::fixed("::")),
                  pool_id = stringr::word(cond, 2, sep = stringr::fixed("::")),
                  prism_replicate = stringr::word(cond, 3, sep = stringr::fixed("::"))) %>%
    dplyr::select(-cond, -V2)

  combat_corrected <- Y %>%
    dplyr::left_join(combat, by = c("prism_replicate", "ccle_name", "pool_id", "culture", "pert_well")) %>%
    .$LFC_cb

  return(combat_corrected)
}

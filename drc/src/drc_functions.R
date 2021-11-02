# Helper functions for the initial processing step of the MTS pipeline

#---- Load Packages ----
library(tidyverse)
library(magrittr)
library(data.table)
library(dr4pl)
library(readr)
library(stats)
library(reshape2)
library(argparse)

#---- Dose-Response Parameters ----
# area under curve given dose-response parameters
compute_auc <- function(l, u, ec50, h, md, MD) {
  f1 = function(x) pmax(pmin((l + (u - l)/(1 + (2^x/ec50)^h)),1), 0 )
  return(tryCatch(integrate(f1, log2(md),log2(MD))$value/(log2(MD/md)),
                  error = function(x) NA))
}

# log IC50 from given dose-response parameters
compute_log_ic50 <- function(l, u, ec50, h, md, MD) {
  if((l >= 0.5) | (u <= 0.5)) {
    return(NA)
  } else {
    f1 = function(x) (l + (u - l)/(1 + (2^x/ec50)^h) - 0.5)
    return(tryCatch(uniroot(f1, c(log2(md), log2(MD)))$root,
                    error = function(x) NA))
  }
}

# area over curve given dose-response parameters
compute_aoc <- function(l, u, ec50, h, md, MD) {
  f1 = function(x) 1 - pmax(pmin((l + (u - l)/(1 + (2^x/ec50)^h)), 1), -1)
  return(tryCatch(integrate(f1, log2(md),log2(MD))$value/(log2(MD/md)),
                  error = function(x) NA))
}

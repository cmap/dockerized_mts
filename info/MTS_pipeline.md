# MTS Processing Pipeline

This document outlines the steps executed by each module of the MTS pipeline that might be used by collaborators, from `LEVEL2` data through biomarker analysis.
* [normalization](#normalization)
* [qc](#qc)
* [lfc](#lfc)
* [batch_correction](#batch_correction)
* [drc](#drc)
* [biomarker](#biomarker)

## normalization

#### Inputs
* `cell_info`: metadata about cell lines/samples (rows)
* `inst_info`: metadata about perturbations (columns)
* `LEVEL2_MFI`: median fluorescence intensities (from Luminex)

#### Outputs
* `LEVEL3_LMFI`: normalized $\log_2(MFI)$
* `compound_key`: overview of the perturbations, projects, and doses

#### Overview
The normalization step $\log_2$ transforms the MFI values for each sample and then normalizes to the control barcodes (`pool_id == "CTLBC"`) in each well. Normalization is done by fitting a spline from the logMFI values to the median logMFI of the control barcode on the replicate. The resulting spline is then used to correct all data on the replicate.

## qc

#### Inputs

#### Outputs

#### Overview

## lfc

#### Inputs

#### Outputs

#### Overview

## batch_correction

#### Inputs

#### Outputs

#### Overview

## drc

#### Inputs

#### Outputs

#### Overview

## biomarker

#### Inputs

#### Outputs

#### Overview

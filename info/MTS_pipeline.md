# MTS Processing Pipeline

This document outlines the steps executed by each module of the MTS pipeline, with particular focus on inputs and outputs, that might be used by collaborators, from `LEVEL2` data through biomarker analysis.
* [normalization](#normalization)
* [qc](#qc)
* [lfc](#lfc)
* [batch_correction](#batch_correction)
* [drc](#drc)
* [biomarker](#biomarker)

---

## normalization

#### Inputs
* `cell_info`: metadata about cell lines/samples (rows)
* `inst_info`: metadata about perturbations (columns)
* `LEVEL2_MFI`: median fluorescence intensities (from Luminex)

#### Outputs
* `LEVEL3_LMFI`: normalized $\log_2(MFI)$ (called logMFI from now on)
* `compound_key`: overview of the perturbations, projects, and doses

#### Overview
The normalization step $\log_2$ transforms the MFI values for each sample and then normalizes to the control barcodes (`pool_id == "CTLBC"`) in each well. Normalization is done by fitting a spline from the logMFI values to the median logMFI of the control barcode on the replicate. The resulting spline is then used to correct all data on the replicate.

---

## qc

#### Inputs
* `LEVEL3_LMFI`: normalized logMFI

#### Outputs
* `QC_TABLE`: quality control metrics for each cell line on each replicate

#### Overview
The QC step calculates a number of quality control metrics for each cell line on each replicate. Two of these metrics are used to filter cell lines out of downstream analysis:

**Dynamic range:**
$$DR = \mu_- - \mu_+$$
where $\mu_-$ is the median logMFI in negative controls and $\mu_+$ is the median in positive controls. Cell lines with $DR > -\log_2{0.3} \approx 1.74$ pass QC on their replicate.

**Error rate:**
$$ER = \frac{FP + FN}{n}$$
where $FP$ and $FN$ are the number of false positives and negatives of the omptimum threshold classifier between positive and negative controls. Cell lines with $ER <= 0.05$ pass QC on their replicate.

In order for a cell line to be included in downstream analyses for a given plate, it must pass QC by the above metrics on more that 50% of replicates (only passing replicates are included).

---

## lfc

#### Inputs
* `LEVEL3_LMFI`: normalized logMFI
* `QC_TABLE`: QC metrics for each cell line on each replicate

#### Outputs
* `LEVEL4_LFC`: log-fold change values for each cell line treatment on each replicate (that passes QC)
* `LEVEL5_LFC`: replicate collapsed log-fold change values for each cell line treatment on each plate

#### Overview
The log-fold change step calculates the $\log_2$ fold-change (LFC) between treatment and negative controls on a given replicate.
$$LFC = \log_2MFI_x - \mu_-$$
where $\log_2MFI_x$ is the logMFI in treatment and $\log_2MFI_{\mu_-}$ is the median logMFI in the negative control.

For those more familiar with viability, LFC is just log-viability such that
$$v = 2^{LFC}$$

The replicate collapsed LFC (`LEVEL5_LFC`) takes the median LFC for a cell line treatment across replicates of a given plate.

---

## batch_correction

#### Inputs
* `LEVEL4_LFC`: replicate level LFC values

#### Outputs
* `LEVEL4_LFC_COMBAT`: replicate level LFC values batch corrected using ComBat
* `LEVEL5_LFC_COMBAT`: replicate collapsed batch corrected LFC values

#### Overview
The batch correction step corrects for batch effects by applying [ComBat](https://pubmed.ncbi.nlm.nih.gov/16632515/) to the `LEVEL4_LFC` data. `LEVEL5_LFC_COMBAT` takes the median ComBat corrected LFC for a cell line treatment across replicates of a given plate.

---

## drc

**Note:** this module is meant to be run per compound per plate and therefore requires splitting into compound folders prior to execution (see [split](../split/README.md) module not covered in this document)

#### Inputs
* `LEVEL4_LFC_COMBAT` or `LEVEL4_LFC`: replicate level LFC data (ComBat corrected if available)

#### Outputs
* `DRC_TABLE`: dose-response curve parameters for each cell line in treatment

#### Overview
The dose-response curve step fits a robust four-parameter logistic curve to the response of each cell line of the form
$$f(x) = b + \frac{a - b}{1 + e^{s \log \frac{x}{EC_{50}}}}$$
where $x$ is the viability of the cell line at each dose. The parameters of the curve are
* $b$: lower asymptote
* $a$: upper asymptote
* $s$: slope
* $EC_{50}$: inflection point

The upper asymptote is constrained to be near 1 and the lower asymptote is constrained to be between 0 and 1. In addition to these parameters, several others are reported in the table (see [column headers](./ColumnHeaders.md)), of particular note are $AUC$, the area under the dose response curve, and $IC_{50}$, the dose at which the curve reaches 50% viability.

---

## biomarker

#### Inputs
* `LEVEL5_LFC_COMBAT` or `LEVEL5_LFC`: replicate collapsed log-fold change data
* `DRC_TABLE` (optional): dose-response parameters

#### Outputs
* `continuous_associations`: correlations with continuous CCLE and DepMap features
* `discrete_associations`: lineage and mutation associations
* `RF_table`: random forest feature level data
* `model_table`: random forest model level results

#### Overview

The biomarker step generates univariate and multivariate associations with CCLE and DepMap data. The results are -omics features that are associated with response to treatment. For more specifics on the types of analyses see [here](./analysis_info.pdf). The datasets used for associations are listed in [`biomarker_files`](../biomarker_files/README.md)

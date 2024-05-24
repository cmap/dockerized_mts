# Release Notes

## CPS011
***

**Replicate correlation**

Added functions to normalize that calculate 2 new metrics:
  1. The median value by detection plate+pool+well of the median difference in logMFI values for a given condition compared to the median of its replicates. If the absolute value of this difference is greater than 3, the plate/pool/well is flagged.
  2. The median value by detection plate/pool of the replicate correlations between each treatment condition and the median value across the replicates. If this correlation is <0.3, the plate/pool/well is flagged.

If both conditions are met (ie, the correlation is <0.3 and the absolute value of the difference in median logMFI is > 3) then this data is removed. A file is also generated ending in *_POOL_WELLS_REMOVED.csv that indicates which values have been removed.

* Removed unnamed columns (index) in QC_TABLE download


## MTS025, CPS011, APS003

Added the floor range QC metric that looks at the separation between cell line signal (LMFI) in negative control and LMFI signal from a bead  without its complementary target barcode present. Like with dynamic range, data from cell lines with separation < log2(0.3) are removed from the detection plate.


## MTS024, CPS010, APS002
***

* Dose Response 
The dose response curve fitting module was revised substantially, motivated by examples where poor DRC fits were returned. Changes include:
  1. The module now attempts to fit the data points using a number of optimization methods and initializations using the dr4pl and drc packages. It then returns the fit with the lowest Mean Squared Error (MSE).
  2. The module constrains fits on single agent screens to have a slope parameter,s >0, to support a decreasing slope solution. This reflects the assumption that the assay aims to detect the reduction of cell viability by test agents. For combination screens, fits can have an increasing slope to detect antagonistic effects between agents.
  3. The Riemann AUC is also provided in the DRC table for each profile. In scenarios where a fit does not succeed, fit parameters are NA but the Riemann AUC is still provided.
  4. An error in the computation of R^2 of the dose-response curve fit has been corrected

* Single-compound report and combination_solo report to use the same Rmd file

* In rare occurrences where wells were reported skipped during the plate preparation, data for those wells are now filtered out
* Lineages subabbreviations and abbreviations using OncoTree notation
* Biomarkers updated to DepMap 23Q4 data

* A value of 1 is now added to all mfi values in the raw_data matrix to prevent log(0)

## EPS001
* Removed IC50 values from Extended Day Data Processing

## MTS023, CPS009
***
* Biomarkers updated to DepMap 23Q2 data 

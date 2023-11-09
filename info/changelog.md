# Release Notes

## MTS024, CPS010, APS002
***

* Dose Response 
The dose response curve fitting module was revised substantially, motivated by examples where poor DRC fits were returned. Changes include:
  1. The module now attempts to fit the data points using a number of optimization methods and initializations using the dr4pl and drc packages. It then returns the fit with the lowest Mean Squared Error (MSE).
  2. The module constrains fits on single agent screens to have a decreasing slope, which reflects the assumption that the assay aims to detect the reduction of cell viability by test agents. For combination screens, fits can have an increasing slope to detect antagonistic effects between agents.
  3. The Riemann AUC is also provided in the DRC table for each profile. In scenarios where a fit does not succeed, fit parameters are NA but the Riemann AUC is still provided.

* Single-compound report and combination_solo report to use the same Rmd file

* In rare occurrences where wells were reported skipped during the plate preparation, data for those wells are now filtered out
* Lineages subabbreviations and abbreviations using OncoTree notation
* Gene Expression (GE) controlling for lineage is an avaialble continuous association feature

* A value of 1 is now added to all mfi values in the raw_data matrix to prevent log(0)


## MTS023, CPS009
***
* Biomarkers updated to DepMap 23Q2 data 

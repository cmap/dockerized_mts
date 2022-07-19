# Biomarker Files

This module downloads relevant biomarker feature files from [taiga](https://cds.team/taiga/) and which are also available from [DepMap](https://depmap.org/portal/download/all/) for non-Broad collaborators.

## File info

The files downloaded from taiga by `biomarker_tables.R` are equivalent to the following files:

- `Achilles_gene_effect.csv` (CRISPR dependencies)
- `CCLE_expression.csv` (gene expression)
- `primary-screen-replicate-collapsed-logfold-change.csv` (repurposing)
- `D2_Achilles_gene_dep_scores.csv` (shRNA)
- `CCLE_metabolomics_20190502.csv` (metablomics)
- `protein_quant_current_normalized.csv` (proteomics)
- `CCLE_RPPA_20181003.csv` (RPPA)
- `CCLE_miRNA_20181103.gct` (miRNA)
- `CCLE_gene_cn.csv` (copy number)
- `CCLE_mutations.csv` (mutations)
- `sample_info.csv` (lineages)

## Transformation

Each file is then transformed into matrix form and the column headers are simplified with the data type appended to allow for combining datasets (e.g. gene expression columns become `GE_<GENE>` and CRISPR columns become `XPR_<GENE>`)

# Column Headers

Bolded columns are especially important while unbolded columns are primarily for internal use or unused. Italicized columns will only appear for combination perturbations.

### LEVEL2 through LEVEL5

| Column | Description |
|:-------|:------------|
| prism_replicate | Sample plate replicate |
| rid | Cell line ID |
| profile_id | Concatenation of replicate and well |
| **ccle_name** | Cell line name |
| **pool_id** | Cell line pool |
| **culture** | Cell line culture (e.g. PR500) |
| mfc_plate_id | |
| mfc_plate_name | |
| pert_dose | Perturbation dose (numeric) |
| pert_dose_unit | Perturbation dose units |
| **pert_id** | Perturbation Broad ID |
| pert_idose | Perturbation dose with units |
| **pert_iname** | Perturbation name (e.g. AZ-628) |
| pert_itime | Assay length with units |
| pert_mfc_desc | Perturbation description|
| pert_mfc_id | Broad perturbation ID with batch suffix |
| pert_mfc_plate | |
| **pert_plate** | Sample compound plate |
| **pert_time** | Assay length |
| pert_time_unit | Assay length units |
| pert_type | Perturbation type (e.g. negative control) |
| **pert_vehicle** | Perturbation vehicle (e.g. DMSO) |
| **pert_well** | Sample well |
| x_group_by | Grouping variable for samples across replicates |
| x_partner | Collaborator name |
| x_pert_plate | |
| **x_project_id** | Project name (e.g. Validation Compounds) |
| x_replicate | |
| x_source_well | |
| is_well_failure | QC indicator (failures removed after LEVEL2)
| **logMFI_norm** | logMFI normalized to control barcodes |
| **logMFI** | log<sub>2 </sub> median fluorescence intensity |
| feature_id | |
| **LFC** | log<sub>2</sub> fold-change relative to control vehicle (this is median collapsed across replicates in LEVEL5) |
| **LFC_cb** | ComBat corrected LFC (this is median collapsed across replicates in LEVEL5) |

### QC\_TABLE

| Column | Description |
|:-------|:------------|
| **prism_replicate** | Sample plate replicate |
| **ccle_name** | Cell line name |
| **pert_time** | Assay length |
| rid | Cell line ID |
| **pool_id** | Cell line pool |
| **culture** | Cell line culture |
| **pert_plate** | Sample compound plate |
| ctl_vehicle_md | Control vehicle median logMFI |
| trt_poscon_md | Positive control median logMFI |
| ctl_vehicle_mad | Control vehicle MAD logMFI |
| trt_poscon_mad | Positive control MAD logMFI |
| ssmd | Strictly-standardized mean difference between positive and negative controls |
| nnmd | Null-normalized mean difference between positive and negative controls |
| **error_rate** | Error rate between positive and negative controls |
| **dr** | Dynamic range (difference in control medians) |
| **pass** | Boolean indicating whether cell line passed QC |

### DRC\_TABLE

| Column | Description |
|:-------|:------------|
| **min_dose** | Minimum dose of perturbation |
| **max_dose** | Maximum dose of perturbation |
| **upper_limit** | Upper limit of the curve |
| **ec50** | Inflection point or relative IC50 of the  curve |
| **slope** | Slope of the dose-response curve |
| **lower_limit** | Lower limit of the curve |
| convergence | Did the fit converge? |
| **auc** | Area under the curve |
| **log2.ic50** | log<sub>2</sub> of the absolute IC50 of the curve|
| mse | Mean-squared error of the curve fit |
| R2 | r-squared of the curve fit |
| **varied_iname** | Perturbation name for the test perturbation |
| **varied_id** | Broad ID for the test perturbation |
| **ccle_name** | Cell line name |
| **culture** | Cell line culture |
| pert_time | Assay length |
| pert_plate | Compound plate |
| *added_compounds* | Perturbation name(s) for anchor compound(s) |
| *added_doses* | Perturbation dose(s) for anchor compound(s) |
| *added_ids* | Perturbation ID(s) for anchor compound(s) |

### discrete\_associations

| Column | Description |
|:-------|:------------|
| **effect_size** | Difference in means between groups |
| **feature** | Feature defining groups |
| **feature_type** | Type of feature |
| p.value | p-value |
| **pert_dose** | Perturbation dose |
| **pert_id** | Perturbation ID |
| **pert_iname** | Perturbation name |
| pert_plate | Compound plate |
| pert_time | Assay length |
| **q.value** | q-value (corrected p-value) |
| t_stat | t statistic |
| *added_compounds* | Perturbation name(s) for anchor compound(s) |
| *added_doses* | Perturbation dose(s) for anchor compound(s) |
| *added_ids* | Perturbation ID(s) for anchor compound(s) |

### continuous\_associations

| Column | Description |
|:-------|:------------|
| NegativeProb | Posterior probability that beta is negative |
| PositiveProb | Posterior probability that beta is positive |
| PosteriorMean | Adaptive shrinkage moderated effect size estimate |
| PosteriorSD | Standard deviation of the PosteriorMean
| betahat | Effect size estimate |
| **coef** | Correlation coefficient |
| feature | Correlated feature |
| feature_type | Type of correlated feature
| lfdr |  Local FDR value |
| lfsr | Local FSR value |
| p.val | p-value for correlation coefficient |
| **pert_dose** | Perturbation dose |
| **pert_id** | Perturbation ID |
| **pert_iname** | Perturbation name |
| pert_plate | Compound plate |
| pert_time | Assay length |
| **q.val** | q-value for correlation coefficient |
| qvalue | q-value for beta |
| rank | Feature rank |
| sebetahat | Beta standard error |
| svalue | s-value |
| *added_compounds* | Perturbation name(s) for anchor compound(s) |
| *added_doses* | Perturbation dose(s) for anchor compound(s) |
| *added_ids* | Perturbation ID(s) for anchor compound(s) |

### RF\_table

| Column | Description |
|:-------|:------------|
| **RF.imp.mean** | Mean feature importance |
| RF.imp.sd | Feature importance standard deviation |
| RF.imp.stability | Fraction of trees using the feature |
| **feature** | Feature name |
| **model** | Dataset used for features |
| **pert_dose** | Perturbation dose |
| **pert_id** | Perturbation ID |
| **pert_iname** | Perturbation name |
| pert_plate | Compound plate |
| pert_time | Assay length |
| rank | Feature rank |
| *added_compounds* | Perturbation name(s) for anchor compound(s) |
| *added_doses* | Perturbation dose(s) for anchor compound(s) |
| *added_ids* | Perturbation ID(s) for anchor compound(s) |

### model\_table

| Column | Description |
|:-------|:------------|
| MSE | Mean squared error of the model |
| MSE.se | Standard error of the MSE |
| **PearsonScore** | Pearson score of the model |
| **R2** | r-squared of the model |
| **model** | Dataset used for features |
| **pert_dose** | Perturbation dose |
| **pert_id** | Perturbation ID |
| **pert_iname** | Perturbation name |
| pert_plate | Compound plate |
| pert_time | Assay length |
| *added_compounds* | Perturbation name(s) for anchor compound(s) |
| *added_doses* | Perturbation dose(s) for anchor compound(s) |
| *added_ids* | Perturbation ID(s) for anchor compound(s) |

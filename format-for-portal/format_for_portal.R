library(argparse)
source("scripts/reports_functions.R")

parser <- ArgumentParser()
# specify our desired options
parser$add_argument("-d", "--data_dir", default="", help="Input directory")
parser$add_argument("-c", "--compound", help="Compound")
parser$add_argument("-m", "--meta_path", help="Path to folder with lineage and mutation files",
    default="https://s3.amazonaws.com/biomarker.clue.io/annotations/")
parser$add_argument("-q", "--qc_path", help="Path to QC file for project")
parser$add_argument("-b", "--combination", help="Boolean indicating whether compound is a combination")
parser$add_argument("-lfr", "--lfc_four_pattern", default="LEVEL4_LFC_COMBAT", help = "Level 4 LFC file search pattern")
parser$add_argument("-lfv", "--lfc_five_pattern", default="LEVEL5_LFC_COMBAT", help = "Level 5 LFC file search pattern")

# get command line options, if help option encountered print help and exit
args <- parser$parse_args()

REPORT_FILES_SUBDIRECTORY <- "reports_files_by_plot"

#Make report_files_by_plot directory
plot_files_dir <- file.path(args$data_dir, REPORT_FILES_SUBDIRECTORY)
dir.create(plot_files_dir, showWarnings = FALSE)

exp_details_path <- file.path(plot_files_dir, 'experimental_details')
dir.create(exp_details_path, showWarnings = FALSE)

dose_response_path <- file.path(plot_files_dir, 'dose_response')
dir.create(dose_response_path, showWarnings = FALSE)

mutation_effect_path <- file.path(plot_files_dir, 'mutation_effect')
dir.create(mutation_effect_path, showWarnings = FALSE)

correlation_analysis_path <- file.path(plot_files_dir, 'correlation_analysis')
dir.create(correlation_analysis_path, showWarnings = FALSE)

lineage_enrichment_path <- file.path(plot_files_dir, 'lineage_enrichment')
dir.create(lineage_enrichment_path, showWarnings = FALSE)

multivariate_biomarker_path <- file.path(plot_files_dir, 'multivariate_biomarker')
dir.create(multivariate_biomarker_path, showWarnings = FALSE)

viability_path <- file.path(plot_files_dir, 'viability')
dir.create(viability_path, showWarnings = FALSE)

create_correlation_analysis_data_table(args$data_dir, correlation_analysis_path);
create_experimental_details(args$data_dir, exp_details_path);
create_lineage_enrichment_volcano_data(args$data_dir, args$meta_path, lineage_enrichment_path);
create_lineage_enrichment_boxplot_v2(args$data_dir, args$meta_path, lineage_enrichment_path);
create_viability(args$data_dir, viability_path);
create_multivariate_biomarker_files(args$data_dir, multivariate_biomarker_path);
create_mutation_effect_volcano_plot_data(args$data_dir, args$meta_path, mutation_effect_path);
create_mutation_effect_boxplot_data(args$data_dir, args$meta_path, mutation_effect_path);


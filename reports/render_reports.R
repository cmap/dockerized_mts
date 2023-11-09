library(argparse)

parser <- ArgumentParser()
# specify our desired options
parser$add_argument("-d", "--data_dir", default="", help="Input directory")
parser$add_argument("-c", "--compound", help="Compound")
parser$add_argument("-m", "--meta_path", help="Path to folder with lineage and mutation files")
parser$add_argument("-q", "--qc_path", help="Path to QC file for project")
parser$add_argument("-b", "--combination", help="Boolean indicating whether compound is a combination")
parser$add_argument("-lfr", "--lfc_four_pattern", default="LEVEL4_LFC_COMBAT", help = "Level 4 LFC file search pattern")
parser$add_argument("-lfv", "--lfc_five_pattern", default="LEVEL5_LFC_COMBAT", help = "Level 5 LFC file search pattern")

# get command line options, if help option encountered print help and exit
args <- parser$parse_args()

if (as.numeric(args$combination) == 0) {
  # single agent report and dose response curves
  rmarkdown::render("rmarkdown/compound_report.Rmd",
                    output_file = paste0(args$compound, "_report.html"),
                    output_dir = args$data_dir,
                    params = list(data_dir = args$data_dir,
                                  comp = args$compound,
                                  meta_folder = args$meta_path,
                                  lfc_five_pattern = args$lfc_five_pattern))
  rmarkdown::render("rmarkdown/drc_report.Rmd",
                    output_file = paste0(args$compound, "_drc.html"),
                    output_dir = args$data_dir,
                    params = list(data_dir = args$data_dir,
                                  comp = args$compound,
                                  lfc_four_pattern = args$lfc_four_pattern))
} else if (as.numeric(args$combination) == 1) {
  # combination report and dose response curves
  rmarkdown::render("rmarkdown/combination_solo.Rmd",
                    output_file = paste0(args$compound, "_report.html"),
                    output_dir = args$data_dir,
                    params = list(data_dir = args$data_dir,
                                  comp = args$compound,
                                  meta_folder = args$meta_path))
  rmarkdown::render("rmarkdown/combination_drc.Rmd",
                    output_file = paste0(args$compound, "_drc.html"),
                    output_dir = args$data_dir,
                    params = list(data_dir = args$data_dir,
                                  comp = args$compound,
                                  qc_path = args$qc_path))
  rmarkdown::render("rmarkdown/combo_report.Rmd",
                    output_file = paste0(args$compound, "_combination_report.html"),
                    output_dir = args$data_dir,
                    params = list(data_dir = args$data_dir,
                                  comp = args$compound,
                                  qc_path = args$qc_path))
} else {
  print("Invalid combination argument. Must be 1 or 0")
}

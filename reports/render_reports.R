library(argparse)

parser <- ArgumentParser()
# specify our desired options
parser$add_argument("-d", "--data_dir", default="", help="Input directory")
parser$add_argument("-c", "--compound", help="Compound")
parser$add_argument("-m", "--meta_path", help="Path to folder with lineage and mutation files")
parser$add_argument("-q", "--qc_path", help="Path to QC file for project")
parser$add_argument("-b", "--combination", help="Boolean indicating whether compound is a combination")

# get command line options, if help option encountered print help and exit
args <- parser$parse_args()

if (as.numeric(args$combination) == 0) {
  # single agent report and dose response curves
  rmarkdown::render("rmarkdown/compound_report.Rmd",
                    output_file = paste0(args$compound, "_report.html"),
                    output_dir = args$data_dir,
                    params = list(data_dir = args$data_dir,
                                  comp = args$compound,
                                  is_combination=FALSE,
                                  meta_folder = args$meta_path))
  rmarkdown::render("rmarkdown/drc_report.Rmd",
                    output_file = paste0(args$compound, "_drc.html"),
                    output_dir = args$data_dir,
                    params = list(data_dir = args$data_dir,
                                  comp = args$compound))
} else if (as.numeric(args$combination) == 1) {
  # combination report and dose response curves
  rmarkdown::render("rmarkdown/compound_report.Rmd",
                    output_file = paste0(args$compound, "_report.html"),
                    output_dir = args$data_dir,
                    params = list(data_dir = args$data_dir,
                                  comp = args$compound,
                                  is_combination=TRUE,
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

library(argparse)

parser <- ArgumentParser()
# specify our desired options
parser$add_argument("-d", "--data_dir", default="", help="Input directory")
parser$add_argument("-c", "--compound", help="Compound")
parser$add_argument("-m", "--meta_path", help="Path to folder with lineage and mutation files")

# get command line options, if help option encountered print help and exit
args <- parser$parse_args()

lfc_dir <- args$input_dir
out_dir <- args$out

rmarkdown::render("rmarkdown/compound_report.Rmd",
                  output_file = paste0(args$compound, "_report.html"),
                  output_dir = args$data_dir,
                  params = list(data_dir=args$data_dir,
                                comp=args$compound,
                                meta_folder=args$meta_path))

rmarkdown::render("rmarkdown/drc_report.Rmd",
                  output_file = paste0(args$compound, "_drc.html"),
                  output_dir = args$data_dir,
                  params = list(data_dir = args$data_dir,
                                comp="$compound"))
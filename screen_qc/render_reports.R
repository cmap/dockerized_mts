library(argparse)

parser <- ArgumentParser()
# specify our desired options
parser$add_argument("-d", "--data_dir", default="", help="Input directory (build).")
parser$add_argument("-o", "--out_dir", default="", help = "Output directory. Default is working directory.")
parser$add_argument("-n", "--screen_name", default="MTS", help = "Screen name")

# get command line options, if help option encountered print help and exit
args <- parser$parse_args()

rmarkdown::render("rmarkdown/qc_report.Rmd",
                  output_file = paste(args$screen_name, "qc_report.html", sep = "_"),
                  output_dir = args$out_dir,
                  params = list(data_dir=args$data_dir, screen_name=args$screen_name))

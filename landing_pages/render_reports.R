library(argparse)

parser <- ArgumentParser()
# specify our desired options
parser$add_argument("-d", "--data_dir", default="", help="Input directory (project)")

# get command line options, if help option encountered print help and exit
args <- parser$parse_args()

rmarkdown::render("rmarkdown/landing_page.Rmd",
                  output_file = "index.html",
                  output_dir = args$data_dir,
                  params = list(data_dir=args$data_dir))

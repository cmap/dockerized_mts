library(argparse)

parser <- ArgumentParser()
# specify our desired options
parser$add_argument("-d", "--data_dir", default="", help="Input directory (project)")
parser$add_argument("-o", "--out_dir", default="", help = "Output directory. Default is working directory.")
parser$add_argument("-p", "--project_name", default="", help = "Project folder name")
parser$add_argument("-b", "--build_name", default="", help = "Build name")
parser$add_argument("-l", "--val_link", default="", help = "Link to validation compound landing page")
parser$add_argument("-c", "--combination_project", default="0", help = "Project has combination files")

# get command line options, if help option encountered print help and exit
args <- parser$parse_args()

if (as.numeric(args$combination) == 0) {
    combination_project = FALSE
} else if (as.numeric(args$combination) == 1) {
    combination_project = TRUE
} else {
    print("Invalid combination argument. Must be 1 or 0")
}

rmarkdown::render("rmarkdown/landing_page.Rmd",
                  output_file = "index.html",
                  output_dir = args$out_dir,
                  params = list(data_dir=args$data_dir,
                                project_name=args$project_name,
                                build_name=args$build_name,
                                val_link=args$val_link,
                                combination_project=combination_project))

library(argparse)

parser <- ArgumentParser()
# specify our desired options
parser$add_argument("-d", "--data_dir", default="", help="Input directory (project)")
parser$add_argument("-o", "--out_dir", default="", help = "Output directory. Default is working directory.")
parser$add_argument("-p", "--project_name", default="", help = "Project folder name")
parser$add_argument("-b", "--build_name", default="", help = "Build name")
parser$add_argument("-l", "--val_link", default="", help = "Link to validation compound landing page")
parser$add_argument("-c", "--combination_project", default="0", help = "Project has combination files")
parser$add_argument("-qc", "--no_mts_qc", default="0", help = "Flag to not run MTS report QC code chunk")
parser$add_argument("-bc", "--no_batch_correct", default="0", help = "Flag indicating there was no batch correction")

# get command line options, if help option encountered print help and exit
args <- parser$parse_args()

if (as.numeric(args$combination_project) == 0) {
    combination_project = FALSE
} else if (as.numeric(args$combination_project) == 1) {
    combination_project = TRUE
} else {
    print("Invalid combination argument. Must be 1 or 0")
}

if (as.numeric(args$no_mts_qc) == 0) {
  run_mts_qc = TRUE
} else if (as.numeric(args$no_mts_qc) == 1) {
  run_mts_qc = FALSE
} else {
  print("Invalid MTS QC flag argument. Must be 1 or 0")
}

if (as.numeric(args$no_batch_correct) == 0) {
  batch_correct = TRUE
} else if (as.numeric(args$no_batch_correct) == 1) {
  batch_correct = FALSE
} else {
  print("Invalid batch correction argument. Must be 1 or 0")
}


rmarkdown::render("rmarkdown/landing_page.Rmd",
                  output_file = "index.html",
                  output_dir = args$out_dir,
                  params = list(data_dir=args$data_dir,
                                project_name=args$project_name,
                                build_name=args$build_name,
                                val_link=args$val_link,
                                combination_project=combination_project,
                                run_mts_qc=run_mts_qc,
                                batch_correct=batch_correct))

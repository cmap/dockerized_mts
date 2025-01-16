library(argparse)
library(DT)
library(tidyverse)
library(ggthemes)
library(magrittr)
library(cowplot)

parser <- ArgumentParser()
# specify our desired options
parser$add_argument("-d", "--data_dir", default="", help="Input directory (project)")
parser$add_argument("-o", "--out_dir", default="", help = "Output directory. Default is working directory.")
parser$add_argument("-p", "--project_name", default="", help = "Project folder name")
parser$add_argument("-b", "--build_name", default="", help = "Build name")
parser$add_argument("-c", "--combination_project", action="store_true", help = "Flag, project has combination files")
parser$add_argument("-bc", "--no_batch_correct", action="store_true", help = "Flag indicating there was no batch correction")

# get command line options, if help option encountered print help and exit
params <- parser$parse_args()


if (params$no_batch_correct) {
  file_text <- c(
    "QC" = "QC metrics",
    "LEVEL3_NORMALIZED_COUNTS" = "Normalized counts",
    "LEVEL4_LFC" = "Viability data",
    "LEVEL5_LFC" = "Replicate-collapsed viability data",
    "DRC" = "Dose response curve data"
  )
} else {
 file_text <- c(
  "QC" = "QC metrics",
  "LEVEL3_LMFI" = "Raw and normalized fluorescence values",
  "LEVEL4_LFC_COMBAT" = "Viability data",
  "LEVEL5_LFC_COMBAT" = "Replicate-collapsed viability data",
  "DRC" = "Dose response curve data"
)
}

biomarker_text <- c(
  "continuous" = "Continuous associations",
  "discrete" = "Discrete associations",
  "model" = "Random forest model statistics",
  "RF" = "Random forest features"
)

matrix_text <- c(
  "LFC" = "Log-fold change matrix",
  "AUC" = "AUC matrix",
  "IC50" = "IC50 matrix"
)

combination_text <- c(
  "synergy" = "Synergy Table",
  "bliss_mss" = "Bliss MSS Table"
)


# get paths to data files
data_files <- list.files(file.path(params$data_dir, "data"))
data_filesp <- paste0("./", data_files)
data_files <- paste0("./", params$project_name,"/","data","/",data_files)
proj_length <- length(strsplit(params$project_name, split = "_", fixed = T)[[1]])
names(data_files) <- stringr::word(data_filesp, proj_length + 1, -2, sep = fixed("_"))


download_files = data.frame(
  title=character(0),
  type=character(0),
  url=character(0),
  project=character(0),
  build=character(0)
) #instantiate

for (i in 1:length(data_files)) {
  if (names(data_files)[i] %in% names(file_text)) {
    download_files %<>% add_row(
      title=file_text[names(data_files)[i]],
      type="compound_data",
      url=file.path(str_to_lower(params$project_name), str_replace(data_files[i], "./", "")),
      project=params$project_name,
      build=params$build_name
    )
  }
}

for (i in 1:length(data_files)) {
  if (names(data_files)[i] %in% names(biomarker_text)) {
    download_files %<>% add_row(
      title=biomarker_text[names(data_files)[i]],
      type="biomarker_data",
      url=file.path(str_to_lower(params$project_name), str_replace(data_files[i], "./", "")),
      project=params$project_name,
      build=params$build_name
    )
  }
}



for (i in 1:length(data_files)) {
  if (names(data_files)[i] %in% names(matrix_text)) {
    download_files %<>% add_row(
      title=matrix_text[names(data_files)[i]],
      type="depmap",
      url=file.path(str_to_lower(params$project_name), str_replace(data_files[i], "./", "")),
      project=params$project_name,
      build=params$build_name
    )
  }
}


#add row with location for zip file
download_files %<>% add_row(
    title="Project Downloads",
    type="all",
    url=file.path(str_to_lower(params$project_name), params$project_name, "data", paste0(params$project_name, ".zip")),
    project=params$project_name,
    build=params$build_name
)

#combination files
if (params$combination_project) {
  for (i in 1:length(data_files)) {
    if (names(data_files)[i] %in% names(combination_text)) {
      download_files %<>% add_row(
        title=combination_text[names(data_files)[i]],
        type="combination_data",
        url=file.path(str_to_lower(params$project_name), str_replace(data_files[i], "./", "")),
        project=params$project_name,
        build=params$build_name
      )
    }
  }
}


#add row with location for zip file
download_files %<>% add_row(
      title="Project Downloads",
      type="all",
      url=file.path(str_to_lower(params$project_name), params$project_name, "data", paste0(params$project_name, ".zip")),
      project=params$project_name,
      build=params$build_name
    )

write.csv(download_files, file.path(params$data_dir, "data", "downloads.csv"), row.names=FALSE)
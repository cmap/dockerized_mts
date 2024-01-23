# Normalization Module

This module takes in mean fluorescence intensity (MFI) values in a matrix and produces long tables with logMFI and normalized logMFI values (**note:** all logs are log base 2). The module also produces a compound key which tracks the compounds in the data set.

## Normalization overview

Each detection well contains 10 control barcodes in increasing abundances as spike-in controls. A monotonic smooth p-spline is fit for each control barcode detection well to normalize the abundance of each barcode to the corresponding value in the plate-wise median vehicle profiles. Next, all the logMFI values in the well are transformed through the inferred spline function to correct for amplification and detection artifacts.

## Docker image

To install the docker image from [Docker Hub](https://hub.docker.com/repository/docker/prismcmap/norm-module) run:

```
docker pull prismcmap/norm-module:latest
```

To get a specific version replace `latest` with the version desired.

## Execution

The entrypoint for the Docker is `aws_batch.sh` which is a wrapper around `normalize.R` for more information using R run

```
Rscript normalize.R --help
usage: normalize.R [-h] [-b BASE_DIR] [-o OUT] [-a ASSAY] [-n NAME]

optional arguments:
  -h, --help            show this help message and exit
  -b BASE_DIR, --base_dir BASE_DIR
                        Input Directory
  -o OUT, --out OUT     Output path. Default is working directory
  -a ASSAY, --assay ASSAY
                        Assay string (e.g. PR500)
  -n NAME, --name NAME  Build name. Default is none
  -x LIST, --exclude_bcids LIST  Comma separated List of barcode_ids to exclude
```

### Example usage with R

R execution requires installing the correct R packages which are outlined in the `docker_base` module.

```
Rscript normalize.R -b ~/Desktop/clue_data -o ~/Desktop/mts_results -a PR500 -n PMTS001
```

### Example usage with Docker

Docker execution requires mounting directories with the `-v` option in order to obtain results.
 
```
docker run \
  -it \
  -v ~/Desktop/clue_data:/in_data \
  -v ~/Desktop/mts_results:/out_data \
  prismcmap/norm-module:latest \
  -b /in_data \
  -o /out_data \
  -a PR500 \
  -n PMTS001
```
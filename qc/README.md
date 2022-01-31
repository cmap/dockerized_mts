# QC Module

This module calculates cell line level QC metrics based on normalized logMFI values.

## QC overview

Separability between negative and positive control treatments is assessed. In particular, we use the error rate of the optimum simple threshold classifier between the control samples for each cell line and plate combination. Additionally, we filter based on the dynamic range of each cell line. We filter out cell lines with error rate above 0.05 and a dynamic range less than ~1.74 from the downstream analysis. Any cell line that has less than 2 passing replicates is also omitted for the sake of reproducibility.

## Docker image

To install the docker image from [Docker Hub](https://hub.docker.com/repository/docker/cmap/qc-module) run:

```
docker pull cmap/qc-module:latest
```

To get a specific version replace `latest` with the version desired.

## Execution

The entrypoint for the Docker is `aws_batch.sh` which is a wrapper around `qc.R` for more information using R run

```
Rscript qc.R --help
usage: qc.R [-h] [-b BASE_DIR] [-o OUT] [-n NAME]

optional arguments:
  -h, --help            show this help message and exit
  -b BASE_DIR, --base_dir BASE_DIR
                        Input Directory
  -o OUT, --out OUT     Output path. Default is working directory
  -n NAME, --name NAME  Build name. Default is none
```

### Example usage with R

R execution requires installing the correct R packages which are outlined in the `docker_base` module.

```
Rscript qc.R -b ~/Desktop/clue_data -o ~/Desktop/mts_results -n PMTS001
```

### Example usage with Docker

Docker execution requires mounting directories with the `-v` option in order to obtain results.

```
docker run \
  -it \
  -v ~/Desktop/clue_data:/in_data \
  -v ~/Desktop/mts_results:/out_data \
  cmap/qc-module:latest \
  -b /in_data \
  -o /out_data \
  -n PMTS001
```

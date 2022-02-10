# LFC Module

This module calculates log-fold change values for each cell line in each condition relative to control vehicle and requires the output of the normalization and QC modules.

## Log-fold change overview

We compute log-fold change by normalizing with respect to the median negative control for each plate. The resulting `LEVEL4` data contains all log-fold change values while the `LEVEL5` data contains median collapsed values across replicates. Because LFC is log2 the values can easily be converted to fold-change (or viability) by taking 2^LFC.

## Docker image

To install the docker image from [Docker Hub](https://hub.docker.com/repository/docker/cmap/lfc-module) run:

```
docker pull cmap/lfc-module:latest
```

To get a specific version replace `latest` with the version desired.

## Execution

The entrypoint for the Docker is `aws_batch.sh` which is a wrapper around `calc_lfc.R` for more information using R run

```
Rscript calc_lfc.R --help
usage: calc_lfc.R [-h] [-b BASE_DIR] [-o OUT] [-n NAME]

optional arguments:
  -h, --help            show this help message and exit
  -b BASE_DIR, --base_dir BASE_DIR
                        Input directory. Default is working directory
  -o OUT, --out OUT     Output path. Default is working directory
  -n NAME, --name NAME  Build name. Default is none
```

### Example usage with R

R execution requires installing the correct R packages which are outlined in the `docker_base` module.

```
Rscript calc_lfc.R -b ~/Desktop/clue_data -o ~/Desktop/mts_results -n PMTS001
```

### Example usage with Docker

Docker execution requires mounting directories with the `-v` option in order to obtain results.

```
docker run \
  -it \
  -v ~/Desktop/clue_data:/in_data \
  -v ~/Desktop/mts_results:/out_data \
  cmap/lfc-module:latest \
  -b /in_data \
  -o /out_data \
  -n PMTS001
```

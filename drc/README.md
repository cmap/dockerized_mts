# DRC Module

This module fits dose-response curves to the viability values for each cell line. It requires the output of the LFC module.

## Dose-response overview

We fit a robust four-parameter logistic curve to the response of each cell line to the compound using [dr4pl](https://cran.r-project.org/web/packages/dr4pl/dr4pl.pdf) and calculate the AUC and IC50 based on those curves. The functions used to calculate these values are located in [`src/drc_functions.R`](./src/drc_functions.R).

## Docker image

To install the docker image from [Docker Hub](https://hub.docker.com/repository/docker/cmap/drc-module) run:

```
docker pull cmap/drc-module:latest
```

To get a specific version replace `latest` with the version desired.

## Execution

The entrypoint for the Docker is `aws_batch.sh` which is a wrapper around `drc_compound.R` for more information using R run

```
Rscript drc_compound.R --help
usage: drc_compound.R [-h] [-i INPUT_DIR] [-o OUT]

optional arguments:
  -h, --help            show this help message and exit
  -i INPUT_DIR, --input_dir INPUT_DIR
                        Input directory with one level 4 LFC file
  -o OUT, --out OUT     Output directory
```

### Example usage with R

R execution requires installing the correct R packages which are outlined in the `docker_base` module.

```
Rscript drc_compound.R -i ~/Desktop/clue_data/project/compound_1 -o ~/Desktop/mts_results/project/compound_1
```

### Example usage with Docker

Docker execution requires mounting directories with the `-v` option in order to obtain results.

```
docker run \
  -it \
  -v ~/Desktop/clue_data/project/compound_1:/in_data \
  -v ~/Desktop/mts_results/project/compound_1:/out_data \
  cmap/drc-module:latest \
  -i /in_data \
  -o /out_data
```

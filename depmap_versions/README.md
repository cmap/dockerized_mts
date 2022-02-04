# DepMap Versions Module

This module makes wide versions (matrices) of log-fold change, AUC, and IC50 that are compatible with upload to the [DepMap portal](https://depmap.org/portal/interactive/).

## Docker image

To install the docker image from [Docker Hub](https://hub.docker.com/repository/docker/prismcmap/depmap_versions) run:

```
docker pull prismcmap/depmap_versions:latest
```

To get a specific version replace `latest` with the version desired.

## Execution

The entrypoint for the Docker is `aws_batch.sh` which is a wrapper around `make_matrices.R` for more information using R run

```
Rscript make_matrices.R --help
usage: make_matrices.R [-h] [-p PROJECT_DIR] [-o OUT] [-n NAME]

optional arguments:
  -h, --help            show this help message and exit
  -p PROJECT_DIR, --project_dir PROJECT_DIR
                        Project directory
  -o OUT, --out OUT     Output directory
  -n NAME, --name NAME  Build name. Default is none
```

### Example usage with R

R execution requires installing the correct R packages which are outlined in the `docker_base` module.

```
Rscript make_matrices.R -p ~/Desktop/clue_data/project -o ~/Desktop/mts_results/project -n PMTS001
```

### Example usage with Docker

Docker execution requires mounting directories with the `-v` option in order to obtain results.

```
docker run \
  -it \
  -v ~/Desktop/clue_data/project:/in_data \
  -v ~/Desktop/mts_results/project:/out_data \
  prismcmap/depmap_versions:latest \
  -p /in_data \
  -o /out_data \
  -n PMTS001
```

# Compound Summary Module

## Compound Summary Module Overview

Calculate summary metrics for compounds in a project. The module takes in a project directory and searches for the following patterns:

  - `LEVEL4_LFC_{COMBAT}`
  - `discrete_associations.csv`
  - `continuous_associations.csv`
  - `model_table.csv`
  - `RF_table.csv`


## Docker image

To install the docker image from [Docker Hub](https://hub.docker.com/repository/docker/prismcmap/compound_summary) run:

```
docker pull prismcmap/compound_summary:latest
```

To get a specific version replace `latest` with the version desired.

## Execution

The entrypoint for the Docker is `aws_batch.sh` which is a wrapper around `compound_summary.R` for more information using R run

```
Rscript compound_summary.R --help
usage: compound_summary.R [-h] [-i INPUT_DIR] [-o OUT]

optional arguments:
  -h, --help            show this help message and exit
  -i INPUT_DIR, --input_dir INPUT_DIR
                        Input directory
  -o OUT, --out OUT     Output directory
```

### Example usage with R

R execution requires installing the correct R packages which are outlined in the `docker_base` module.

```
Rscript compound_summary.R -i ~/Desktop/clue_data/project/data -o ~/Desktop/mts_results/project/data
```

### Example usage with Docker

Docker execution requires mounting directories with the `-v` option in order to obtain results.

```
docker run \
  -it \
  -v ~/Desktop/clue_data/project/data:/in_data \
  -v ~/Desktop/mts_results/project/data:/out_data \
  prismcmap/compound_summary:latest \
  -i /in_data \
  -o /out_data
```

# Batch Correction Module

This module uses [ComBat](https://www.bioconductor.org/packages/devel/bioc/vignettes/sva/inst/doc/sva.pdf) to correct log-fold change values for batch effects. It requires the output of the LFC module.

## Batch correction overview

Log-fold changes are corrected for batch effects coming from pools and culture conditions using the ComBat algorithm as described in [Johnson et al.](https://pubmed.ncbi.nlm.nih.gov/16632515/). This module is typically run after concatenating PR500 and PR300+ data together.

## Docker image

To install the docker image from [Docker Hub](https://hub.docker.com/repository/docker/cmap/batch-correct-module) run:

```
docker pull cmap/batch-correct-module:latest
```

To get a specific version replace `latest` with the version desired.

## Execution

The entrypoint for the Docker is `aws_batch.sh` which is a wrapper around `batch_correct.R` for more information using R run

```
Rscript batch_correct.R --help
usage: batch_correct.R [-h] [-b BASE_DIR] [-o OUT] [-n NAME]

optional arguments:
  -h, --help            show this help message and exit
  -b BASE_DIR, --base_dir BASE_DIR
                        Input directory
  -o OUT, --out OUT     Output path. Default is working directory
  -n NAME, --name NAME  Build name. Default is none
```

### Example usage with R

R execution requires installing the correct R packages which are outlined in the `docker_base` module.

```
Rscript batch_correct.R -b ~/Desktop/clue_data -o ~/Desktop/mts_results -n PMTS001
```

### Example usage with Docker

Docker execution requires mounting directories with the `-v` option in order to obtain results.

```
docker run \
  -it \
  -v ~/Desktop/clue_data:/in_data \
  -v ~/Desktop/mts_results:/out_data \
  cmap/batch-correct-module:latest \
  -b /in_data \
  -o /out_data \
  -n PMTS001
```

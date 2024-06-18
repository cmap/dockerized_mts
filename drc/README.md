# DRC Module

This module fits dose-response curves to the viability values for each cell line. It requires the output of the LFC module.

## Dose-response overview

For each cell line passing QC, we attempt to fit a 4-parameter log logistic dose-response curve and for each curve we compute summary statistics including AUC and IC50. An IC50 is reported only if the fitted curve crosses 50% viability within the dose range of the experiment. If the curve fit does not succeed, fit parameters are omitted, and only the Riemann AUC is provided.

The fit is performed with the following restrictions:
- For single-agent studies, We support the predicted viability to decrease with increasing dose by constraining the slope parameter (s> 1e-5). For combination studies, we relax this slope constraint since the two agents could be antagonistic.

- For single-agent studies, we constrain the upper limit of the fit to be between 0.8 and 1.01. For combination studies, this constraint is relaxed as the viability at the anchor dose can be lower, and the upper limit of the fit is between 0 and 1.

- We constrain the lower limit of the fit to be between 0 and 1.

Since the nonlinear optimization underlying the curve fit can return a local optimum, we first fit the data using a number of different optimization methods and initial conditions implemented in the [drc](https://cran.r-project.org/web/packages/drc/drc.pdf) and [dr4pl](https://cran.r-project.org/web/packages/dr4pl/dr4pl.pdf) packages, and then report the fit with the smallest mean squared error (MSE). The dr4pl package provides a robust fit in some scenarios where the naive fit fails to converge. The functions used to calculate the fit values are located in [`src/drc_functions.R`](./src/drc_functions.R).

## Docker image

To install the docker image from [Docker Hub](https://hub.docker.com/repository/docker/prismcmap/drc-module) run:

```
docker pull prismcmap/drc-module:latest
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
  prismcmap/drc-module:latest \
  -i /in_data \
  -o /out_data
```

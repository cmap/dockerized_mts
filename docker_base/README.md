# Docker Base

For making the base image for clue-mts docker. Installs necessary R packages to run the MTS pipeline.


## Docker image

To install the docker image from [Docker Hub](https://hub.docker.com/repository/docker/cmap/base-clue-mts) run:

```
docker pull cmap/base-clue-mts:latest
```

To get a specific version replace `latest` with the version desired.

## Installing packages locally

If you have R installed and would like to install the packages to your local machine run

```
Rscript install_packages.R
```

# Assemble

## Assemble overview

Collates information from JCSV files from scanners to capture measured fluorescent intensity (MFI) values.

## Docker image

To install the docker image from [Docker Hub](https://hub.docker.com/repository/docker/prismcmap/merino) run:

```
docker pull prismcmap/merino:latest
```

To get a specific version replace `latest` with the version desired.

## Execution

Help text is available using the command: 

```
docker run prismcmap/merino --help
```

The entrypoint for the Docker is `batch_assemble.sh` which is a wrapper around `assemble.py`. It can be inspected to see how the environment within the Docker container is set up

### Example usage with Docker

Docker is the recommended method for running the assemble module as it uses a deprecated version of python (Python 2.7). 

Docker execution requires mounting directories with the `-v` option in order to obtain results.


```
docker run \
  -it \
  -v ~/TEST:/data/ \
  prismcmap/merino:latest \
  -csv_filepath /data/lxb/TEST005_PR500_120H_X1_P6/TEST005_PR500_120H_X1_P6.jcsv \
  -plate_map_path /data/map_src/TEST005.src \
  -out ~/TEST/build/ -assay_type PR500.CS5.3
```

### Usage with Python

While running using Docker is the preferred method, it is possible to set up a conda environment with the required versions of python and other packages.

More information can be found in the [merino Github Repo](https://github.com/cmap/merino)





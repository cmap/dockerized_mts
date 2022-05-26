# Screen-level QC Report

**For internal use**

This module creates a build level QC report.

## QC report overview

QC reports generated with RMarkdown (files in [`rmarkdown`](./rmarkdown)).

## Docker image

To install the docker image from [Docker Hub](https://hub.docker.com/repository/docker/prismcmap/qc-screen) run:

```
docker pull prismcmap/qc-screen:latest
```

To get a specific version replace `latest` with the version desired.

## Execution

The entrypoint for the Docker is `aws_batch.sh` which is a wrapper around `render_reports.R` which calls the rmarkdown files. For more information using R run

```
Rscript render_reports.R --help
usage: render_reports.R [-h] [-d DATA_DIR] [-o OUT_DIR] [-n SCREEN_NAME]

optional arguments:
  -h, --help            show this help message and exit
  -d DATA_DIR, --data_dir DATA_DIR
                        Input directory (build).
  -o OUT_DIR, --out_dir OUT_DIR
                        Output directory. Default is working directory.
  -n SCREEN_NAME, --screen_name SCREEN_NAME
                        Screen name
```

### Example usage with R

R execution requires installing the correct R packages which can be installed by running:

```
Rscript src/install_packages.R
```

Then the module can be run;

```
Rscript render_reports.R -d ~/Desktop/MTS016 -o ~/Desktop/MTS016 -n MTS016
```

### Example usage with Docker

Docker execution requires mounting directories with the `-v` option in order to obtain results.

```
docker run \
  -v ~/Desktop/MTS016:/data \
  -it prismcmap/qc-screen \
  -d /data \
  -o /data \
  -n MTS016
```

# Landing Page Module

**For internal use**

This module creates the landing pages for each project with links to downloads and reports.

## Landing page overview

Landing pages are generated with RMarkdown (files in [`rmarkdown`](./rmarkdown)).

## Docker image

To install the docker image from [Docker Hub](https://hub.docker.com/repository/docker/prismcmap/landing) run:

```
docker pull prismcmap/landing:latest
```

To get a specific version replace `latest` with the version desired.

## Execution

The entrypoint for the Docker is `aws_batch.sh` which is a wrapper around `render_reports.R` which calls the rmarkdown files. For more information using R run

```
Rscript render_reports.R --help
usage: render_reports.R [-h] [-d DATA_DIR] [-o OUT_DIR] [-p PROJECT_NAME]
                        [-l VAL_LINK]

optional arguments:
  -h, --help            show this help message and exit
  -d DATA_DIR, --data_dir DATA_DIR
                        Input directory (project)
  -o OUT_DIR, --out_dir OUT_DIR
                        Output directory. Default is working directory.
  -p PROJECT_NAME, --project_name PROJECT_NAME
                        Project folder name
  -l VAL_LINK, --val_link VAL_LINK
                        Link to validation compound landing page
```

### Example usage with R

R execution requires installing the correct R packages which can be installed by running:

```
Rscript src/install_packages.R
```

Then the module can be run;

```
Rscript render_reports.R -d ~/Desktop/clue_data/project -o ~/Desktop/mts_results/project -p project -l https://analysis.clue.io/validation_compunds/index.html
```

### Example usage with Docker

Docker execution requires mounting directories with the `-v` option in order to obtain results.

```
docker run \
  -it \
  -v ~/Desktop/clue_data/project:/in_data \
  -v ~/Desktop/mts_results/project:/out_data \
  prismcmap/landing:latest \
  -d /in_data \
  -o /out_data \
  -p project \
  -l https://analysis.clue.io/validation_compunds/index.html
```

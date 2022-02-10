# Report Module

This module creates the HTML reports for each compound.

## Reports overview

Reports are generated with RMarkdown (files in [`rmarkdown`](./rmarkdown)).

## Docker image

To install the docker image from [Docker Hub](https://hub.docker.com/repository/docker/prismcmap/reports) run:

```
docker pull prismcmap/reports:latest
```

To get a specific version replace `latest` with the version desired.

## Execution

The entrypoint for the Docker is `aws_batch.sh` which is a wrapper around `render_reports.R` which calls the rmarkdown files. For more information using R run

```
Rscript render_reports.R --help
usage: render_reports.R [-h] [-d DATA_DIR] [-c COMPOUND] [-m META_PATH]
                        [-q QC_PATH] [-b COMBINATION]

optional arguments:
  -h, --help            show this help message and exit
  -d DATA_DIR, --data_dir DATA_DIR
                        Input directory
  -c COMPOUND, --compound COMPOUND
                        Compound
  -m META_PATH, --meta_path META_PATH
                        Path to folder with lineage and mutation files
  -q QC_PATH, --qc_path QC_PATH
                        Path to QC file for project
  -b COMBINATION, --combination COMBINATION
                        Boolean indicating whether compound is a combination
```

### Example usage with R

R execution requires installing the correct R packages which can be installed by running:

```
Rscript src/install_packages.R
```

Then the module can be run;

```
Rscript render_reports.R -d ~/Desktop/clue_data/project/COMP1 -o ~/Desktop/mts_results/project/COMP1 -c COMP1 -m https://biomarker.clue.io -q ~/Desktop/mts_results/project/QC_TABLE.csv -b 0
```

### Example usage with Docker

Docker execution requires mounting directories with the `-v` option in order to obtain results.

```
docker run \
  -it \
  -v ~/Desktop/clue_data/project:/in_data \
  -v ~/Desktop/mts_results/project:/out_data \
  prismcmap/landing:latest \
  -d /in_data/COMP1 \
  -o /out_data/COMP1 \
  -c COMP1 \
  -m https://biomarker.clue.io \
  -q /in_data/QC_TABLE.csv \
  -b 0
```

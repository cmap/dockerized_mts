# Collate Module

## Collate Module Overview

Collates assemble output, module takes in a project directory and searches for the following patterns:

  `{PROJECT_DIR}/\*/assemble/\*/*_LEVEL2_MFI_*.gctx`

  `{PROJECT_DIR}/\*/assemble/\*/*_LEVEL2_COUNT_*.gctx`


The file structure :
 ```
  {PROJECT_DIR}/
      {PLATE_DIR}/
          assemble/
             {PLATE_DIR}
                *_LEVEL2_MFI_*.gctx
                *_LEVEL2_COUNT_*.gctx
      {PLATE_DIR}/
 ```     


## Docker image

To install the docker image from [Docker Hub](https://hub.docker.com/repository/docker/prismcmap/collate) run:

```
docker pull prismcmap/collate:latest
```

To get a specific version replace `latest` with the version desired.

## Execution

The entrypoint for the Docker is `collate_bash.sh` which is a wrapper around `collate.py` for more information using python run

```
$ python collate.py --help
usage: collate.py [-h] --proj_dir PROJ_DIR --cohort_name COHORT_NAME --build_dir BUILD_DIR [--search_pattern SEARCH_PATTERN]
                  [--verbose]

optional arguments:
  -h, --help            show this help message and exit
  --proj_dir PROJ_DIR, -pd PROJ_DIR
                        Required: Path to the pod directory you want to run
                        card on (default: None)
  --cohort_name COHORT_NAME, -cn COHORT_NAME
                        Required: String designating the prefix to each build
                        file eg. PCAL075-126_T2B (default: None)
  --build_dir BUILD_DIR, -bd BUILD_DIR
                        Required: outfolder for build files (default: None)
  --search_pattern SEARCH_PATTERN, -sp SEARCH_PATTERN
                        Search for this string in the directory, only run
                        plates which contain it. Default is wildcard (default:
                        *)
  --verbose, -v         Whether to print a bunch of output (default: False)

```

### Example usage with Docker

*Docker is the recommended method for running the collate module as it uses a deprecated version of python (Python 2.7).*
Docker execution requires mounting directories with the `-v` option in order to obtain results.


```
docker run \
  -it \
  -v ~/{PROJECT_DIR}:/data/ \
  prismcmap/collate:latest \
  -pd /data/ -bd /data/build -cn {COHORT_NAME}
```


### Example usage with Python

Running python requires an environment set up to use merino. See merino repo here: https://github.com/cmap/merino

```
python collate.py -pd {PROJECT_DIR} -bd {PROJECT_DIR}/build -cn {COHORT_NAME}
```

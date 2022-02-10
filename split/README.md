# Split Module

##  Split Overview

Extracts required files from the build for dose response curves

File structure expected as output of split module (used in pivot_splits):
 ```
  {OUT_DIR}/
      {PROJECT_DIR}/
          {PLATE_DIR}/
              {PERT_DIR}/
                  *_LEVEL4_LFC_*.csv
              {PERT_DIR}/
                  *_LEVEL4_LFC_*.csv
 ```     



## Docker image

To install the docker image from [Docker Hub](https://hub.docker.com/repository/docker/prismcmap/pivot_splits) run:

```
docker pull prismcmap/split:latest
```

To get a specific version replace `latest` with the version desired.

## Execution

The entrypoint for the Docker is `split_bash.sh` which is a wrapper around `split.py` for more information using python run

```
$ python split.py --help
usage: split.py [-h] --build_path BUILD_PATH [--project PROJECT] [--pert PERT]
                [--pert_plate PERT_PLATE] [--sig_id_cols SIG_ID_COLS] --out
                OUT [--verbose]

optional arguments:
  -h, --help            show this help message and exit
  --build_path BUILD_PATH, -b BUILD_PATH
                        Build path (default: None)
  --project PROJECT, -pr PROJECT
                        Project name (default: None)
  --pert PERT, -p PERT  Pert ID (default: None)
  --pert_plate PERT_PLATE, -pp PERT_PLATE
                        Pert plate (default: None)
  --sig_id_cols SIG_ID_COLS, -s SIG_ID_COLS
                        Comma separated list of col names to create sig_ids if
                        not present (default:
                        pert_plate,culture,pert_id,pert_idose,pert_time)
  --out OUT, -o OUT     Output for project level folders (default: None)
  --verbose, -v         Whether to print a bunch of output (default: False)
```

### Example usage with Docker
Docker execution requires mounting directories with the `-v` option in order to obtain results.


```
docker run \
  -it \
  -v ~/{PROJECT_DIR}:/data/ \
  prismcmap/split:latest \
  -b data/build \
  -o data/projects/ \
  -p BRD-A000000 \
  -pr PRJ_A \
  -pp PRJ_A001 \
```


### Example usage with Python

```
python split.py -b {PROJECT_DIR}/build -o {PROJECT_DIR}/projects/ --pert BRD-A000000 --pert_plate PRJ_A001 --project PRJ_A
```

# Deal Module

## Deal Module Overview

Distributes files to make build for each project

## Docker image

To install the docker image from [Docker Hub](https://hub.docker.com/repository/docker/prismcmap/deal) run:

```
docker pull prismcmap/deal:latest
```

To get a specific version replace `latest` with the version desired.

## Execution

The entrypoint for the Docker is `deal_bash.sh` which is a wrapper around `deal.py` for more information using python run

```
$ python deal.py --help
usage: deal.py [-h] [--build_path BUILD_PATH] [--only_key ONLY_KEY]
               [--project PROJECT] [--sig_id_cols SIG_ID_COLS] [--out OUT]
               [--verbose]

Distributes files to make build for each project

optional arguments:
  -h, --help            show this help message and exit
  --build_path BUILD_PATH, -b BUILD_PATH
                        Build path (default: None)
  --only_key ONLY_KEY, -k ONLY_KEY
                        key to extract. Useful if parallelizing, only listed
                        keys will be concatenated (default: None)
  --project PROJECT, -p PROJECT
                        Project to extract (default: None)
  --sig_id_cols SIG_ID_COLS, -s SIG_ID_COLS
                        Comma separated list of col names to create sig_ids if
                        not present (default:
                        pert_plate,culture,pert_id,pert_idose,pert_time)
  --out OUT, -o OUT     Output for collated build (default: None)
  --verbose, -v         Whether to print a bunch of output (default: False)

```

### Example usage with Docker
Docker execution requires mounting directories with the `-v` option in order to obtain results.


```
docker run \
  -it \
  -v ~/{PROJECT_DIR}:/data/ \
  prismcmap/deal:latest \
  -b /data/build \
  -o /data/projects
```


### Example usage with Python

Running python requires an environment set up to use merino. See merino repo here: https://github.com/cmap/merino

```
python deal.py -b {PROJECT_DIR}/build -o {PROJECT_DIR}/projects
```

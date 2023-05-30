# Stack Module
## Stack Overview (Testing for Jenkins)


Merge two or more builds. Used in pipeline to merge assays with different cell lines.

## Docker image

To install the docker image from [Docker Hub](https://hub.docker.com/repository/docker/prismcmap/stack) run:

```
docker pull prismcmap/stack:latest
```

To get a specific version replace `latest` with the version desired.

## Execution

The entrypoint for the Docker is `stack_bash.sh` which is a wrapper around `stack.py` for more information using python run

```
$ python stack.py --help
usage: stack.py [-h] [--build_paths BUILD_PATHS] [--build_name BUILD_NAME]
                [--only_stack_keys ONLY_STACK_KEYS]
                [--sig_id_cols SIG_ID_COLS] [--out OUT] [--verbose]

optional arguments:
  -h, --help            show this help message and exit
  --build_paths BUILD_PATHS, -b BUILD_PATHS
                        Comma separated list of build paths to collate
                        (default: None)
  --build_name BUILD_NAME, -n BUILD_NAME
                        Build Name, prepended to files (default: None)
  --only_stack_keys ONLY_STACK_KEYS, -k ONLY_STACK_KEYS
                        Comma separated list of keys. Useful if parallelizing,
                        only listed keys will be concatenated (default: None)
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
docker run -it \
-v /path_to/test_files:/data  \
prismcmap:stack \
-build_paths /data/PR300/build/,/data/PR500/build/ \
-n TEST \
-o /data/TEST_BUILD/build
```

`--build_paths` is a comma-separated list (no whitespace) of build paths.


### Example usage with Python

```
python stack.py -build_paths /{PROJECT_DIR}/PR300/build/,/{PROJECT_DIR}/PR500/build/ \
-n TEST \
-o /{PROJECT_DIR}/TEST_BUILD/build
```

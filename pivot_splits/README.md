# Pivot Splits Module

##  Pivot Splits Overview

Adaptation of pivot module for AWS file structure; used on per-compound basis. Converts long-form CSV files into more storage efficient GCTx format.

File structure expected (output of split module):
 ```
  {SPLIT_DIR}/
      {PROJECT_DIR}/
          {PLATE_DIR}/
              *_LEVEL4_LFC_*.csv
          {PLATE_DIR}/
              *_LEVEL4_LFC_*.csv
 ```     



## Docker image

To install the docker image from [Docker Hub](https://hub.docker.com/repository/docker/prismcmap/pivot_splits) run:

```
docker pull prismcmap/pivot_splits:latest
```

To get a specific version replace `latest` with the version desired.

## Execution

The entrypoint for the Docker is `pivot_splits_bash.sh` which is a wrapper around `pivot_splits.py` for more information using python run

```
$ python pivot_splits.py --help
usage: pivot_splits.py --splits_dir SPLITS_DIR --project PROJECT --pert_plate
                       PERT_PLATE --pert PERT
                       [--search_pattern SEARCH_PATTERN]
                       [--data_header DATA_HEADER] [--cid_header CID_HEADER]
                       [--rid_header RID_HEADER]
                       [--col_metadata_headers COL_METADATA_HEADERS]
                       [--row_metadata_headers ROW_METADATA_HEADERS]
                       [--write_gctx | --write_gct]
                       [--append_dims | --no-append-dims] [--verbose] [-h]

Convert compound CSVs to GCT format

required arguments:
  --splits_dir SPLITS_DIR, -d SPLITS_DIR
                        Output folder of split module
  --project PROJECT, -pr PROJECT
                        Project name
  --pert_plate PERT_PLATE, -pp PERT_PLATE
                        Pert plate
  --pert PERT, -p PERT  Pert ID
  --search_pattern SEARCH_PATTERN, -s SEARCH_PATTERN
                        Search pattern within
                        build_path/project/pert_plate/pert (default:
                        *LEVEL4*.csv)

optional arguments:
  --data_header DATA_HEADER, -dhd DATA_HEADER
                        Columns required for data (default: LFC)
  --cid_header CID_HEADER, -chd CID_HEADER
                        Columns for column metadata. (Default: profile_id)
  --rid_header RID_HEADER, -rhd RID_HEADER
                        Columns for row metadata. (Default: rid)
  --col_metadata_headers COL_METADATA_HEADERS, -cmh COL_METADATA_HEADERS
                        Columns that belong in col_metadata_df
  --row_metadata_headers ROW_METADATA_HEADERS, -rmh ROW_METADATA_HEADERS
                        Columns that belong in row_metadata_df
  --write_gctx          Use HDF5 based GCTX format
  --write_gct           Use text based GCT format (default)
  --append_dims         Add dimensions to filename (default: true)
  --no-append-dims
  --verbose, -v         Whether to print a bunch of output
  -h, --help            show this help message and exit

```

### Example usage with Docker
Docker execution requires mounting directories with the `-v` option in order to obtain results.


```
docker run \
  -it \
  -v ~/{PROJECT_DIR}:/data/ \
  prismcmap/pivot_splits:latest \
  --splits_dir /data/projects/compound_files/ \
  --pert BRD-A000000 \
  --pert_plate PRJ_A001 \
  --project PRJ_A
```


### Example usage with Python

Running python requires an environment set up to use merino. See merino repo here: https://github.com/cmap/merino

```
python pivot_splits.py --splits_dir {PROJECT_DIR}/projects/compound_files/ --pert BRD-A000000 --pert_plate PRJ_A001 --project PRJ_A
```

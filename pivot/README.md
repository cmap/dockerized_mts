# Pivot Module

## Pivot Module Overview

Converts long-form CSV files into more storage efficient GCTx format.

## Docker image

To install the docker image from [Docker Hub](https://hub.docker.com/repository/docker/prismcmap/pivot) run:

```
docker pull prismcmap/pivot:latest
```

To get a specific version replace `latest` with the version desired.

## Execution

The entrypoint for the Docker is `pivot_bash.sh` which is a wrapper around `pivot.py` for more information using python run

```
$ python pivot.py --help
usage: pivot.py [-h] --csv CSV --data_header DATA_HEADER [--out OUT]
                [--outname OUTNAME] [--cid_header CID_HEADER]
                [--rid_header RID_HEADER]
                [--col_metadata_headers COL_METADATA_HEADERS]
                [--row_metadata_headers ROW_METADATA_HEADERS]
                [--write_gctx | --write_gct]
                [--append_dims | --no-append-dims] [--verbose]

Utility to convert long form csvs that represent matrix form data into GCT objects which reduces redundancies in data and file sizeAssumes that metadata is identical for each unique value of cid_header or rid_header within the (row|col)_metadata_headers

required arguments:
  --csv CSV, -d CSV     Path to CSV
  --data_header DATA_HEADER, -dhd DATA_HEADER
                        Columns required for data
  --out OUT, -o OUT     Output path. Defualt is current working directory.

options:
  --outname OUTNAME, -f OUTNAME
                        Filename for resulting GCT file. (Default: result)
  --cid_header CID_HEADER, -chd CID_HEADER
                        Columns for column metadata. (Default: profile_id)
  --rid_header RID_HEADER, -rhd RID_HEADER
                        Columns for row metadata. (Default: rid)
  --col_metadata_headers COL_METADATA_HEADERS, -cmh COL_METADATA_HEADERS
                        Columns that belong in col_metadata_df
  --row_metadata_headers ROW_METADATA_HEADERS, -rmh ROW_METADATA_HEADERS
                        Columns that belong in row_metadata_df
  --write_gctx          Use HDF5 based GCTX format
  --write_gct           Use text based GCT format
  --append_dims         Add dimensions to filename (default: true)
  --no-append-dims

```

### Example usage with Docker
Docker execution requires mounting directories with the `-v` option in order to obtain results.


```
docker run \
  -it \
  -v ~/{PROJECT_DIR}:/data/ \
  prismcmap/pivot:latest \
  -d /data/build/TEST_LEVEL5_LFC_COMBAT_n100x500.csv \
  -dhd "LFC.cb"
  -o /data/build/
  -f TEST_LEVEL5_LFC
```


### Example usage with Python

Running python requires an environment set up to use merino. See merino repo here: https://github.com/cmap/merino

```
python pivot.py -d {PROJECT_DIR}/build/TEST_LEVEL5_LFC_COMBAT_n100x500.csv -dhd "LFC.cb" -o {PROJECT_DIR}/build/ -f TEST_LEVEL5_LFC
```

# QC flag module

This module takes in a level3 data table along with a qc_table and produces a table of qc flags by instance.

## QC flag overview

The fundamental unit subjected to flagging here is an *instance*. We define an *instance* as a single datapoint, ie the MFI and/or count values for a given cell line in a particular detection well.



## Docker image

To install the docker image from [Docker Hub](https://hub.docker.com/repository/docker/prismcmap/norm-module) run:

```
docker pull prismcmap/qc_flags:latest
```

To get a specific version replace `latest` with the version desired.

## Execution

The entrypoint for the Docker is `qc_flags_bash.sh` which is a wrapper around `apply_qc_flags.py`. For more information run `python apply_qc_flags.py -h`.

```
$ python apply_qc_flags.py --help
usage: apply_qc_flags.py [-h] --build_path BUILD_PATH [--thresholds THRESHOLDS] [--name NAME] [--verbose]

Creates a table of flagged instances based on threshold for various signal and count metrics.

arguments:
  -h, --help            show this help message and exit
  --build_path BUILD_PATH, -b BUILD_PATH
                        Build path (default: None)
  --thresholds THRESHOLDS, -t THRESHOLDS
                        QC thresholds to use (default: None)
  --name NAME, -n NAME  Build name. (default: )
  --verbose, -v         Whether to print a bunch of output (default: False)

```
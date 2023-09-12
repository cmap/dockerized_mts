# QC flag module

This module takes in a level3 data table along with a qc_table and produces a table of qc flags by instance.

## QC flag overview

The fundamental unit subjected to flagging here is an *instance*. We define an *instance* as a single datapoint, ie the MFI and/or count values for a given cell line in a particular detection well.

## Docker image

To install the docker image from [Docker Hub](https://hub.docker.com/repository/docker/prismcmap/norm-module) run:

```
docker pull prismcmap/???:latest
```
```
#!/usr/bin/env bash

#change the version number for each new build
docker build --platform linux/amd64 -t prismcmap/qc_flags:dev -t prismcmap/qc_flags:latest -t prismcmap/qc_flags:v0.1.0 --rm=true .


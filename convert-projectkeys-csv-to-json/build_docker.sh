#!/usr/bin/env bash

#change the version number for each new build
docker build --platform linux/amd64 -t prismcmap/csv2json:develop \
-t prismcmap/csv2json:v0.3.0 \
--rm=true .

#!/usr/bin/env bash

#change the version number for each new build
docker build -t prismcmap/csv2json:latest \
-t prismcmap/csv2json:v0.0.1 \
--rm=true .

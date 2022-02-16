#!/usr/bin/env bash

#change the version number for each new build
docker build -t prismcmap/csv2json:latest \
-t prismcmap/csv2json:v0.1.0 \
--rm=true .

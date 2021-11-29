#!/usr/bin/env bash

#change the version number for each new build
docker build -t cmap/norm-module:dev -t prismcmap/norm-module:latest -t prismcmap/norm-module:v0.0.1 --rm=true .

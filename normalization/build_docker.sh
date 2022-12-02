#!/usr/bin/env bash

#change the version number for each new build
docker build --platform linux/amd64 -t prismcmap/norm-module:dev -t prismcmap/norm-module:latest -t prismcmap/norm-module:v0.1.0 --rm=true .


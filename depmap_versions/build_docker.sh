#!/usr/bin/env bash

#change the version number for each new build
docker build -t prismcmap/depmap_versions:latest -t prismcmap/depmap_versions:v0.1.0 --rm=true .

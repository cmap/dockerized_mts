#!/usr/bin/env bash

#change the version number for each new build
docker build --platform linux/amd64 -t prismcmap/depmap_versions:latest -t prismcmap/depmap_versions:v0.1.0 --rm=true .

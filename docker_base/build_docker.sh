#!/usr/bin/env bash

#change the version number for each new build
docker build --platform linux/amd64 -t cmap/base-clue-mts:latest -t cmap/base-clue-mts:v0.0.1 --rm=true .

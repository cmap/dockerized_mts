#!/usr/bin/env bash

#change the version number for each new build
docker build -t prismcmap/pivot_splits:latest -t prismcmap/pivot_splits:v0.0.4 --rm=true .

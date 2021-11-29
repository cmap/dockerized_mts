#!/usr/bin/env bash

#change the version number for each new build
docker build -t prismcmap/merge-csvs:latest -t prismcmap/merge-csvs:v0.0.1 --rm=true .

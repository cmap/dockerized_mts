#!/usr/bin/env bash

#change the version number for each new build
docker build -t prismcmap/extract-biomarker:latest -t prismcmap/extract-biomarker:v0.0.1 --rm=true .

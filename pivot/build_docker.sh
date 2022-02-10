#!/usr/bin/env bash

#change the version number for each new build
docker build -t prismcmap/pivot:latest -t prismcmap/pivot:v0.0.3 --rm=true .

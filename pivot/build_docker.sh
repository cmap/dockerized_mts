#!/usr/bin/env bash

#change the version number for each new build
docker build --platform linux/amd64 -t prismcmap/pivot:latest -t prismcmap/pivot:v0.0.3 --rm=true .

#!/usr/bin/env bash

#change the version number for each new build
docker build --platform linux/amd64 -t prismcmap/deal:latest -t prismcmap/deal:v0.2.0 --rm=true .

#!/usr/bin/env bash

#change the version number for each new build
docker build -t prismcmap/deal:latest -t prismcmap/deal:v0.0.1 --rm=true .

#!/usr/bin/env bash

#change the version number for each new build
docker build --platform linux/amd64 -t prismcmap/lfc-module:latest -t prismcmap/lfc-module:0.0.1 --rm=true .

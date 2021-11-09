#!/usr/bin/env bash

#change the version number for each new build
docker build -t prismcmap/split:latest -t prismcmap/split:v0.0.3 --rm=true .

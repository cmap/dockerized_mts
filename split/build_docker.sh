#!/usr/bin/env bash

#change the version number for each new build
docker build -t prismcmap/split:latest -t prismcmap/split:v0.2.0 --rm=true .

#!/usr/bin/env bash

#change the version number for each new build
docker build -t prismcmap/stack:latest -t prismcmap/stack:v0.0.1 --rm=true .

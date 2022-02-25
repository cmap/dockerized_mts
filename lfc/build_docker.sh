#!/usr/bin/env bash

#change the version number for each new build
docker build -t prismcmap/lfc-module:latest -t prismcmap/lfc-module:0.0.1 --rm=true .

#!/usr/bin/env bash

#change the version number for each new build
docker build -t prismcmap/collate:latest -t prismcmap/collate:v0.0.1 --rm=true .

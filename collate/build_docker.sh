#!/usr/bin/env bash

#change the version number for each new build
docker build -t prismcmap/collate:latest -t prismcmap/collate:v0.1.0 --rm=true .

#!/usr/bin/env bash

#change the version number for each new build
docker build -t prismcmap/merino:latest -t prismcmap/merino:v0.1.1 --rm=true .

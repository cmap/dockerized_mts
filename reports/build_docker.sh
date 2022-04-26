#!/usr/bin/env bash

#change the version number for each new build
docker build --platform linux/amd64 -t prismcmap/reports:latest -t prismcmap/reports:v0.1.2 --rm=true .

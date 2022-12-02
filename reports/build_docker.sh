#!/usr/bin/env bash

#change the version number for each new build
docker build -t prismcmap/reports:latest -t prismcmap/reports:v0.1.2 --rm=true .

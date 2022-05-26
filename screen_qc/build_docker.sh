#!/usr/bin/env bash

#change the version number for each new build
docker build -t prismcmap/qc-screen:dev -t prismcmap/qc-screen:latest -t prismcmap/qc-screen:v0.0.1 --rm=true .

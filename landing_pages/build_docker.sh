#!/usr/bin/env bash

#change the version number for each new build
docker build -t prismcmap/landing:latest -t prismcmap/landing:v0.1.0 --rm=true .

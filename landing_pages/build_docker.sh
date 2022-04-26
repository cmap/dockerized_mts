#!/usr/bin/env bash

#change the version number for each new build
docker build --platform linux/amd64 -t prismcmap/landing:latest -t prismcmap/landing:v0.1.1 --rm=true .

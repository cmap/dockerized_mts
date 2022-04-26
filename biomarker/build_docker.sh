#!/usr/bin/env bash
docker build --platform linux/amd64 -t prismcmap/biomarker-module:latest -t prismcmap/biomarker-module:v0.1.1 --rm=true .

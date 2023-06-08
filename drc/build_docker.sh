#!/usr/bin/env bash
docker build --platform linux/amd64 -t prismcmap/drc-module:robust_DRC -t prismcmap/drc-module:v0.0.1 --rm=true .

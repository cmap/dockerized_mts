#!/usr/bin/env bash
docker build --platform linux/amd64 -t prismcmap/drc:robust_DRC -t prismcmap/drc:v0.0.1 --rm=true .

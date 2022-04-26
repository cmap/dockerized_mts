#!/usr/bin/env bash
docker build --platform linux/amd64 -t cmap/drc-module:latest -t cmap/drc-module:v0.0.1 --rm=true .

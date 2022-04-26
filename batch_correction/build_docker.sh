#!/usr/bin/env bash
docker build --platform linux/amd64 -t cmap/batch-correct-module:dev -t cmap/batch-correct-module:v0.0.1 --rm=true .

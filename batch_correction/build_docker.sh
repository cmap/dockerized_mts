#!/usr/bin/env bash
docker build --platform linux/amd64 -t prismcmap/batch-correct-module:latest -t prismcmap/batch-correct-module:v0.0.1 --rm=true .

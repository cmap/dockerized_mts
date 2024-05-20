#!/usr/bin/env bash
docker build --platform linux/amd64 -t prismcmap/drc:testing --rm=true .

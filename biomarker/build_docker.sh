#!/usr/bin/env bash
docker build --platform linux/amd64 -t prismcmap/biomarker:testing --rm=true .

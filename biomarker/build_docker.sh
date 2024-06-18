#!/usr/bin/env bash
docker build --platform linux/amd64 -t prismcmap/biomarker:production --rm=true .

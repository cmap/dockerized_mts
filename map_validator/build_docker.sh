#!/usr/bin/env bash
docker build --platform linux/amd64 -t map-validator:latest -t map-validator:v0.0.1 --rm=true .

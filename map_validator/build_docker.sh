#!/usr/bin/env bash
docker build --platform linux/amd64 -t map-validator:latest -t map-validator:v0.1.0 --rm=true .

#!/usr/bin/env bash

# change the version number for each new build
docker build \
-t prismcmap/register-mts:latest \
-t prismcmap/register-mts:v0.0.1 \
--rm=true .

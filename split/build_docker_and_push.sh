#!/usr/bin/env bash

#VERSION="v0.2.1"
TAG="develop"

#change the version number for each new build
docker build --platform linux/amd64 -t prismcmap/split:$TAG --rm=true .

docker push prismcmap/split:$TAG

# trigger

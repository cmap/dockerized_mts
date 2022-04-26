#!/usr/bin/env bash

VERSION="v0.2.1"
TAG="latest"

#change the version number for each new build
docker build --platform linux/amd64 -t prismcmap/split:$TAG -t prismcmap/split:$VERSION --rm=true .

docker push prismcmap/split:$VERSION
docker push prismcmap/split:$TAG

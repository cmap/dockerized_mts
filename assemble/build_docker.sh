#!/usr/bin/env bash
REPO="prismcmap"
NAME="assemble"

VERSION="v1.0.1" #change the version number for each new build
TAG="latest"

#change the version number for each new build
docker build --platform linux/amd64 -t $REPO/$NAME:$TAG -t $REPO/$NAME:$VERSION --rm=true .

docker push $REPO/$NAME:$VERSION
docker push $REPO/$NAME:$TAG

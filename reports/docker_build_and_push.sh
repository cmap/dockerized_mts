#!/usr/bin/env bash
REPO="prismcmap"
NAME="reports"

#VERSION="v0.2.11" #change the version number for each new build
TAG="testing"

#change the version number for each new build
docker build --platform linux/amd64 -t $REPO/$NAME:$TAG --rm=true .

#docker push $REPO/$NAME:$VERSION
#docker push $REPO/$NAME:$TAG

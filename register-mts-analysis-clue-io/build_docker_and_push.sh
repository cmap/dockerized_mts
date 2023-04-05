#!/usr/bin/env bash
REPO="prismcmap"
NAME="register-mts"

VERSION="v0.2.0" #change the version number for each new build
TAG="latest"

#change the version number for each new build
docker build --platform linux/amd64 -t $REPO/$NAME:$TAG -t $REPO/$NAME:$VERSION --rm=true .

docker push $REPO/$NAME:$VERSION
docker push $REPO/$NAME:$TAG

#v0.2.0 - Fixed issue with reports not being associated when a prior build was made with
# the same project
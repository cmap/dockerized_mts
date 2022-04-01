#!/usr/bin/env bash
REPO="prismcmap"
NAME="register-mts"

VERSION="v0.1.5" #change the version number for each new build
TAG="latest"

#change the version number for each new build
docker build -t $REPO/$NAME:$TAG -t $REPO/$NAME:$VERSION --rm=true .

docker push $REPO/$NAME:$VERSION
docker push $REPO/$NAME:$TAG

#!/usr/bin/env bash
REPO="prismcmap"
NAME="landing_pages"

VERSION="v0.2.2" #change the version number for each new build
TAG="production"

#change the version number for each new build
docker build --platform linux/amd64 -t $REPO/$NAME:$TAG -t $REPO/$NAME:$VERSION --rm=true .

docker push $REPO/$NAME:$VERSION
docker push $REPO/$NAME:$TAG

# trigger
#!/usr/bin/env bash
REPO="prismcmap"
NAME="prep-portal-data"

VERSION="v1.1.1" #change the version number for each new build
TAG="latest"

#change the version number for each new build
docker build --platform linux/amd64 -t $REPO/$NAME:$TAG -t $REPO/$NAME:$VERSION --rm=true .
#
docker push $REPO/$NAME:$VERSION
docker push $REPO/$NAME:$TAG

#v1.0.0 - Changed input flags that may break
#v1.1.0 - Added project file handling
#v1.1.1 - Added project argument passthrough

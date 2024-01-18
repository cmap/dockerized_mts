#!/usr/bin/env bash
REPO="prismcmap"
NAME="remove-data"

#VERSION="v1.1.1" #change the version number for each new build
TAG="develop"

#change the version number for each new build
docker build --platform linux/amd64 -t $REPO/$NAME:$TAG --rm=true .
#
#docker push $REPO/$NAME:$VERSION
#docker push $REPO/$NAME:$TAG

#v1.0.0 - Changed input flags that may break
#v1.1.0 - Added project file handling
#v1.1.1 - Added project argument passthrough

# trigger
#!/usr/bin/env bash
REPO="prismcmap"
NAME="prep-portal-data"

<<<<<<< Updated upstream
VERSION="v1.1.0" #change the version number for each new build
=======
VERSION="v1.0.1" #change the version number for each new build
>>>>>>> Stashed changes
TAG="latest"

#change the version number for each new build
docker build --platform linux/amd64 -t $REPO/$NAME:$TAG -t $REPO/$NAME:$VERSION --rm=true .
#
docker push $REPO/$NAME:$VERSION
docker push $REPO/$NAME:$TAG

<<<<<<< Updated upstream
#v1.0.0 - Changed input flags that may break
#v1.1.0 - Added project file handling
=======
#v1.0.1 - added ic50 as 2^log2_ic50
#v1.0.0 - Changed input flags that may break
>>>>>>> Stashed changes

#!/usr/bin/env bash

VERSION="v0.1.1"
TAG="latest"
#change the version number for each new build
docker build -t prismcmap/collate:$TAG -t prismcmap/collate:$VERSION --rm=true .

#!/usr/bin/env bash
docker push prismcmap/collate:$VERSION
docker push prismcmap/collate:$TAG

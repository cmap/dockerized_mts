#!/usr/bin/env bash
#change the version number for each new build
docker build --platform linux/amd64 -t prismcmap/eps-prep:develop --rm=true .

docker push prismcmap/eps-prep:develop
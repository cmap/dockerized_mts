#!/usr/bin/env bash

#change the version number for each new build
docker build --platform linux/amd64 -t prismcmap/merge-csv-files:test --rm=true .

docker push prismcmap/merge-csv-files:test

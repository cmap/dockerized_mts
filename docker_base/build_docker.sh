#!/usr/bin/env bash

cp -R ../src/install_packages.R .
#change the version number for each new build
docker build -t cmap/base-clue-mts:latest -t cmap/base-clue-mts:v0.0.1 --rm=true .

rm -fr install_packages.R
#!/usr/bin/env bash
docker run -v /Users/jasiedu/WebstormProjects/dockerized_mts/TEST_ALL/:/data/ \
-it cmap/batch-correct-module:dev \
-b /data/build \
-o /data/build \
-n "TEST_PMTS017_PR1000"
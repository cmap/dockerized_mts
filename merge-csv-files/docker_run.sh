#!/bin/bash
docker run --rm \
--name bar2 \
-v /Users/jasiedu/WebstormProjects/PMTS:/cmap/macchiato \
-it prismcmap/merge-csvs \
-d /cmap/macchiato \
-o /cmap/macchiato/out \
-s PMTS0* \
-sp "\t"
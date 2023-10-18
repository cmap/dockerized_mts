#!/usr/bin/env bash

#docker run --rm \
#--name bar2 \
#-v /Users/jasiedu/WebstormProjects/dockerized_mts:/cmap/macchiato \
#-it prismcmap/drc-module \
#-i /cmap/macchiato/foo \
#-o /cmap/macchiato/foo

docker run -it \
  -v /foo/BRD-K00003576:/in_data \
  -v /foo/BRD-K00003576:/out_data \
  prismcmap/drc:robust_DRC \
  -i /in_data \
  -o /out_data

#docker run -it -v /Users/anup/work/1_Projects/wkdir/drc_robust/MTS022_VALIDATION_COMPOUNDS_INTERNAL/PMTS061/BRD-K00003576:/in_data --entrypoint /bin/bash 66bd8fb4c4de
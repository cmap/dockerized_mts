#!/usr/bin/env bash

docker run --rm \
--name bar \
-v ~/WebstormProjects/PMTS018/projects/:/data \
-it prismcmap/landing \
-d /data/mts018_dmc_loxo/MTS018_DMC_LOXO \
-o /data/mts018_dmc_loxo

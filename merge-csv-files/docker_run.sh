#!/usr/bin/env bash
docker run --rm \
--name bar2 \
-v /Users/jasiedu/WebstormProjects/PMTS018/projects/:/cmap/macchiato \
-it prismcmap/merge-csvs \
-d /cmap/macchiato/CPS003_DMC_GENENTECH \
-o /cmap/macchiato/CPS003_DMC_GENENTECH/data \
-s DRC_TABLE.csv \
-ap "true"
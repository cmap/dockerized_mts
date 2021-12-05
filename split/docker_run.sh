#!/usr/bin/env bash

docker run --rm \
--name bar \
-v /Users/jasiedu/WebstormProjects/macchiato/test:/cmap/macchiato \
-e projects="$(cat /Users/jasiedu/WebstormProjects/macchiato/foo.json)" \
-e AWS_BATCH_JOB_ARRAY_INDEX=5 \
-it prismcmap/split \
-b /cmap/macchiato/data/build \
-o /cmap/macchiato/projects
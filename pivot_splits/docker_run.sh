#!/bin/bash

docker run --rm \
--name bar2 \
-v /Users/jasiedu/WebstormProjects/macchiato/projects:/cmap/macchiato \
-e projects="$(cat /Users/jasiedu/WebstormProjects/macchiato/foo.json)" \
-e AWS_BATCH_JOB_ARRAY_INDEX=2 \
-it prismcmap/pivot_splits \
-d /cmap/macchiato/ \
-o /cmap/macchiato/


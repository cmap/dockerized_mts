#!/bin/bash

docker run --rm \
--name bar \
-v /Users/jasiedu/WebstormProjects/macchiato/test:/cmap/macchiato \
-e projects="$(cat /Users/jasiedu/WebstormProjects/macchiato/foo1.json)" \
-e AWS_BATCH_JOB_ARRAY_INDEX=0 \
-it prismcmap/merge-csvs \
-d /cmap/macchiato/projects \
-o /cmap/macchiato/projects
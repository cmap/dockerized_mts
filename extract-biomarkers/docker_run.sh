#!/usr/bin/env bash

docker run \
--rm \
--name foo10 \
-v /Users/jasiedu/WebstormProjects/macchiato/test/projects/:/cmap/macchiato/ \
-e projects="$(cat /Users/jasiedu/WebstormProjects/macchiato/foo1.json)" \
-e AWS_BATCH_JOB_ARRAY_INDEX=0 \
-it prismcmap/extract-biomarker \
-d /cmap/macchiato \
-o /cmap/macchiato \
-x 10


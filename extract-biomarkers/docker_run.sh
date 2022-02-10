#!/usr/bin/env bash
docker run --rm \
--name bar2 \
-v /Users/jasiedu/WebstormProjects/TEST_CPS017_P1000_NEWFMT3:/cmap/macchiato \
-e projects="$(cat /Users/jasiedu/WebstormProjects/macchiato/foo1.json)" \
-e AWS_BATCH_JOB_ARRAY_INDEX=0 \
-it prismcmap/extract-biomarker \
-d /cmap/macchiato/projects \
-o /cmap/macchiato/projects \
-x 10
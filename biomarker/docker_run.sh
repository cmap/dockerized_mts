#!/bin/bash

docker run --rm \
--name bar2 \
-v /Users/jasiedu/WebstormProjects/TEST_CPS017_P1000_NEWFMT3/:/cmap/macchiato \
-v /Users/jasiedu/WebstormProjects/biomarker/.cache/:/cmap/biomarker_cache \
-e projects="$(cat /Users/jasiedu/WebstormProjects/macchiato/foo1.json)" \
-e AWS_BATCH_JOB_ARRAY_INDEX=0 \
-it cmap/biomarker-module:dev \
-b /cmap/macchiato/projects \
-o /cmap/macchiato/projects \
-d "/cmap/biomarker_cache"




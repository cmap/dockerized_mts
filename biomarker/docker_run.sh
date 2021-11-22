#!/bin/bash

docker run --rm \
--name bar2 \
-v /Users/jasiedu/WebstormProjects/TEST_CPS017_P1000_NEWFMT3/:/cmap/macchiato \
-e projects="$(cat /Users/jasiedu/WebstormProjects/macchiato/foo.json)" \
-e AWS_BATCH_JOB_ARRAY_INDEX=0 \
-it cmap/biomarker-module:dev \
-b /cmap/macchiato/projects \
-o /cmap/macchiato/projects \
-d "https://s3.amazonaws.com/biomarker.clue.io/.cache"




#!/usr/bin/env bash

docker run --rm \
--name bar \
-v ~/WebstormProjects/PMTS018/projects/MTS018_VALIDATION_COMPOUNDS/PMTS046:/data \
-e projects=/data/foo.json \
-e AWS_BATCH_JOB_ARRAY_INDEX=0 \
-it prismcmap/reports \
-d /data/BRD-K05804044 \
-c BRD-K05804044 \
-m https://s3.amazonaws.com/biomarker.clue.io
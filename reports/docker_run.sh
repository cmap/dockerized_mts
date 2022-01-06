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

#/cmap/macchiato/619e422b9b8eca00119db024/projects/cps003_dmc_genentech/CPS003_DMC_GENENTECH/PMTS048/BRD-U00093966-001-01-9_BRD-U00093968-001-01-9
#!/usr/bin/env bash


docker run \
--rm \
--name foo110 \
-v /Users/jasiedu/WebstormProjects/build:/data \
-v /Users/jasiedu/WebstormProjects/build/results:/results \
-v /Users/jasiedu/WebstormProjects/project_files/PMTS014_PR500:/projects \
-e projects='[ { "project_id": "MTS014 Validation Compounds", "pert_name": "ZXH 3-26" }, { "project_id": "PDEV_PR300PLUS", "pert_name": "lapatinib" }]' \
-e AWS_BATCH_JOB_ARRAY_INDEX=0 \
-it cmap/clue-mts \
-i /data \
-o /results \
-t "1" \
-a "PR500"


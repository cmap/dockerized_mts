#!/usr/bin/env bash

docker run \
--rm \
--name az-test-2 \
-v /Users/aboghoss/Downloads/MTS015_PR500:/data \
-e projects='[ { "project_id": "MTS015 DMC - Amgen", "pert_name": "ATA6" } ]' \
-e AWS_BATCH_JOB_ARRAY_INDEX=0 \
-it cmap/clue-mts \
-i /data \
-o /data \
-t "1" \
-a "PR500"

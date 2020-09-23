#!/usr/bin/env bash

docker run \
--name pre-test \
-v /Users/aboghoss/Downloads/MTS014_PR300_RERUN:/data \
-e projects='[ { "project_id": "MTS014 Validation Compounds Vibliome", "pert_name": "AZ-628" } ]' \
-e AWS_BATCH_JOB_ARRAY_INDEX=0 \
-it cmap/clue-mts \
-i /data \
-o /data \
-t "0" \
-p /data \
-a "PR300"

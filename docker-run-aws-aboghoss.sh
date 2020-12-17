#!/usr/bin/env bash

docker run \
--rm \
--name az-test-2 \
-v /Users/aboghoss/Downloads/MTS015_PR500:/data \
-e projects='[ { "project_id": "Validation Compounds", "pert_name": "anagrelide" } ]' \
-e AWS_BATCH_JOB_ARRAY_INDEX=0 \
-it aboghoss/clue-mts:dev \
-i /data \
-o /data \
-t "1" \
-a "PR500"

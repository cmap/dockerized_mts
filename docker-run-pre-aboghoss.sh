#!/usr/bin/env bash

docker run \
--name pre-processing \
-v /Users/aboghoss/Downloads/MTS016_PR300:/data \
-e AWS_BATCH_JOB_ARRAY_INDEX=0 \
-it aboghoss/clue-mts:dev \
-i /data \
-o /data \
-t "0" \
-a "PR300P"

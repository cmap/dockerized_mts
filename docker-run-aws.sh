#!/usr/bin/env bash

docker run \
--rm \
--name foo110 \
-v /Users/aboghoss/Desktop/MTS014:/data \
-v /Users/aboghoss/Desktop/MTS014_test:/results \
-e AWS_BATCH_JOB_ARRAY_INDEX=0 \
-it aboghoss/clue-mts:dev \
-i /data \
-p /data \
-o /results \
-a "PR500"

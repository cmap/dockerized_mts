#!/usr/bin/env bash
data_dir="$1"

docker run \
--rm \
--name lfc-calculation \
-v "$data_dir":/data \
-e AWS_BATCH_JOB_ARRAY_INDEX=0 \
-it aboghoss/clue-mts:dev \
-i /data \
-o /data \
-t "2" \
-a "0"

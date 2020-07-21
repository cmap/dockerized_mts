#!/usr/bin/env bash


docker run \
--rm \
--name foo110 \
-v /Users/jasiedu/Downloads/for_jacob:/data \
-v /Users/jasiedu/Downloads/for_jacob:/results \
-e projects="Validation Compounds MTS013,German MTS013,GPER Agonist Ridky MTS013,FG-4592 Kaelin MTS013" \
-e AWS_BATCH_JOB_ARRAY_INDEX=0 \
-it cmap/clue-mts \
-i /data/data \
-o /results/ressults \
-a "PR500"


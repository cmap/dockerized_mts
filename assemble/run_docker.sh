#!/bin/bash


docker run \
-e API_KEY=30582f579da93b567afbd717ca65fb44 \
-e API_URL=https://api.clue.io \
-e PLATES=PMTS.BASE002_PR300P_48H_X2_R3 \
-e AWS_BATCH_JOB_ARRAY_INDEX=0 \
-v /Users/anup/work/1_Projects/assemble_update/:/data/ \
prismcmap/assemble-no-merino \
-config_root /data/ \
-project_code PTEST -replicate_map FALSE \
-assay_type PR300.CS12.3

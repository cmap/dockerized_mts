#!/usr/bin/env bash


docker run \
--rm \
--name foo110 \
-v /Users/jasiedu/WebstormProjects/build:/data \
-v /Users/jasiedu/WebstormProjects/build/results:/results \
-v /Users/jasiedu/WebstormProjects/project_files/PMTS014_PR500:/projects \
-e projects="MTS014 Validation Compounds,German MTS013,GPER Agonist Ridky MTS013,FG-4592 Kaelin MTS013" \
-e AWS_BATCH_JOB_ARRAY_INDEX=0 \
-it cmap/clue-mts \
-i /data \
-p /projects \
-o /results \
-t "2" \
-a "PR500"


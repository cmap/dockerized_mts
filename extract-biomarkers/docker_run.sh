#!/usr/bin/env bash

docker run \
--rm \
--name foo10 \
-v /Users/jasiedu/WebstormProjects/dockerized_mts/extract-biomarkers/continous-associations/:/cmap/continous-associations/ \
-v /Users/jasiedu/WebstormProjects/dockerized_mts/extract-biomarkers/out/:/prism/out/ \
-it prismcmap/extract-biomarker \
--file_name /cmap/continous-associations/continuous_associations.csv \
--default_dataset MTS017 \
--out_dir /prism/out


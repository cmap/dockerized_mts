#!/bin/bash

docker run --rm \
--name bar2 \
-v \
/Users/jasiedu/WebstormProjects/merino/vdb/cell_set_definitions/:/data/ \
-it prismcmap/csv2json \
-f /data/PMTS018_compound_key.csv \
-o /data/PMTS018_compound_key.json


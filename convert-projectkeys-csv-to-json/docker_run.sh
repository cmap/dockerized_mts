#!/usr/bin/env bash

docker run --rm \
--name bar2 \
-v \
/Users/naim/Documents/Work/Troubleshooting/SUSHI-MTS/:/data/ \
-it prismcmap/csv2json:develop \
-f /data/PMTS022_PR500_compound_key.csv \
-o /data/PMTS022_PR500_compound_key.json \
-l LEVEL4_LFC,LEVEL4_LFC_COMBAT,LEVEL5_LFC,LEVEL5_LFC_COMBAT
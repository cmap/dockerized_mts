#!/usr/bin/env bash
docker run --rm \
--name analysis2clue \
--env-file=/Users/jasiedu/.aws/aws_lambda \
-v /Users/jasiedu/WebstormProjects/PMTS/:/cmap/macchiato/ \
-it prismcmap/sync-mts-2-clue \
-s /cmap/macchiato \
-d s3://macchiato.clue.io/tests3



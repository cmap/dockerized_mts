#!/bin/bash

docker run --rm \
--name bar2 \
-v /Users/jasiedu/WebstormProjects/dockerized_mts:/cmap/macchiato \
-e projects="$(cat /Users/jasiedu/WebstormProjects/macchiato/foo.json)" \
-e AWS_BATCH_JOB_ARRAY_INDEX=2 \
-it cmap/drc-module \
-i /cmap/macchiato/projects \
-o /cmap/macchiato/projects

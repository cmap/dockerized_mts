#!/bin/bash

docker run --rm \
--name bar2 \
-v /Users/jasiedu/WebstormProjects/dockerized_mts:/cmap/macchiato \
-it cmap/drc-module \
-i /cmap/macchiato/foo \
-o /cmap/macchiato/foo

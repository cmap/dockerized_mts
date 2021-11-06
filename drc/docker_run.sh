#!/bin/bash

docker run --rm \
--name bar2 \
-v /Users/jasiedu/WebstormProjects/dockerized_mts:/cmap/macchiato \
-e projects="$(cat /Users/jasiedu/WebstormProjects/macchiato/foo.json)" \
-e AWS_BATCH_JOB_ARRAY_INDEX=2 \
-e AWS_REGION=us-east-1 \
-e AWS_ACCESS_KEY_ID=AKIATAWTSI6KDSEGXD6M \
-e AWS_SECRET_ACCESS_KEY=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 \
--log-driver=awslogs \
--log-opt awslogs-region=us-east-1 \
--log-opt awslogs-group=drc-logs \
--log-opt awslogs-stream=drc-module-logs \
--log-opt awslogs-create-group=true \
-it cmap/drc-module \
-i /cmap/macchiato/projects \
-o /cmap/macchiato/projects


docker run
--rm \
--name bar2 \
--log-driver=awslogs \
--log-opt awslogs-region=us-east-1 \
--log-opt awslogs-group=drc-logs \
--log-opt awslogs-stream=drc-module-logs \
--log-opt awslogs-create-group=true \
-it hello-world

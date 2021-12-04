#!/bin/bash
docker run -p 9000:8080 \
--env-file=/Users/jasiedu/.aws/aws_lambda \
map-validator:latest

#!/usr/bin/env bash

docker tag  map-validator:latest 207675869076.dkr.ecr.us-east-1.amazonaws.com/map-validator:latest
docker push 207675869076.dkr.ecr.us-east-1.amazonaws.com/map-validator:latest

# trigger

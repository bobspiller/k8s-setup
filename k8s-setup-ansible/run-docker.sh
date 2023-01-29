#!/bin/bash

docker run -d \
  --privileged \
  --name ubuntu-vagrant \
  --rm \
  -p 2222:22 \
  ubuntu-vagrant:22.04
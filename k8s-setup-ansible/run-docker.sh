#!/bin/bash

docker run -d \
  --privileged \
  --name ubuntu-vagrant \
  --rm \
  -p 2222:22 \
  rockyos-vagrant:9.1
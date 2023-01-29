#!/bin/bash

set -x
ssh-keygen \
    -t rsa -b 4096 \
    -f insecure_vagrant_docker_id \
    -C "insecure_vagrant_docker_id" \
    -P ""

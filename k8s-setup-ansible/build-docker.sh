#!/bin/bash
set -x
TAG=${TAG:-rockyos-vagrant:9.1}
docker build -t ${TAG} .
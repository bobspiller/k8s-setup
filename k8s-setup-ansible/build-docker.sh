#!/bin/bash
set -x
TAG=${TAG:-ubuntu-vagrant:22.04}
docker build -t ${TAG} .
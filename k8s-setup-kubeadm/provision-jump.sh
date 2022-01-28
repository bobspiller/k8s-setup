#!/bin/bash

echo "==== provision-jump.sh"

echo ">>>> Setting kubernetes configuration for vagrant user ..."
mkdir -p $HOME/.kube
cp /vagrant/config/kubeconfig $HOME/.kube/config

echo "==== provision-jump.sh: done"

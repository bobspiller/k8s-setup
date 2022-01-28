#!/bin/bash

echo "===== provision-worker-node.sh"

echo ">>>>> Joining $(hostname) to the cluster ..."
sudo /vagrant/config/join.sh

echo ">>>>> provision-worker-node.sh: done"
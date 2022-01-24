#!/bin/bash

echo "===== $0"

echo ">>>>> Joining $(hostname) to the cluster ..."
sudo /vagrant/config/join.sh

echo ">>>>> $0: done"
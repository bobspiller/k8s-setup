#!/bin/bash

NODE_IP_ADDR=$1
shift

echo "==== provision-control.sh: NODE_IP_ADDR=${NODE_IP_ADDR}"

echo ">>>>> Initializing the control plane ..."
sudo kubeadm init\
 --apiserver-advertise-address=${NODE_IP_ADDR}\
 --pod-network-cidr=192.168.0.0/16\
 --service-cidr=10.240.20.0/24

echo ">>>>> Setting up kubeconfig for $(id -un)..."
VAGRANT_HOME=$HOME
mkdir -p $VAGRANT_HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $VAGRANT_HOME/.kube/config
sudo chown $(id -u):$(id -g) $VAGRANT_HOME/.kube/config
if [ ! -d /vargrant/config ]; then
    mkdir /vagrant/config
fi
cp $VAGRANT_HOME/.kube/config /vagrant/config/kubeconfig

echo ">>>>> Installing the Calico operator ..."
kubectl create -f /vagrant/tigera-operator.yaml

echo ">>>>> Installing Calico CNI implementation ..."
kubectl create -f /vagrant/calico-custom-resources.yaml

echo ">>>>> Generating join script for worker nodes ..."
kubeadm token create --print-join-command > /vagrant/config/join.sh
chmod +x /vagrant/config/join.sh

echo ">>>>> provision-control.sh: done"

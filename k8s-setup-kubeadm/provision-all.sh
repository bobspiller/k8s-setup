#!/bin/bash

echo ">>>>> Checking if module br_netfilter is present ..."
lsmod | grep -q br_netfilter
if [ $? -ne 0 ]; then
  echo ">>>>> ... br_netfilter not found, installing it now"
  sudo modprobe br_netfilter
fi

echo ">>>>> Checking if module overlay is present ..."
lsmod | grep -q overlay
if [ $? -ne 0 ]; then
  echo "... overlay not found, installing it now"
  sudo modprobe overlay
fi

echo ">>>>> Ensure that these modules are loaded at boot time"
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
overlay
EOF

echo ">>>>> Ensure that iptables can see bridged traffic"
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system


echo ">>>>> Installing packages required for installing k8s components"
sudo apt-get update
sudo apt-get install -y\
  ca-certificates\
  curl\
  gnupg\
  lsb-release

echo ">>>>> Adding docker official GPG key"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo ">>>>> Seting up the stable repository"
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo ">>>>> Installing containerd"
sudo apt-get update
sudo apt-get install -y containerd.io

echo ">>>>> Enabling the containerd service"
sudo systemctl enable containerd.service

echo ">>>>> Configuring containerd and restarting"
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo systemctl restart containerd

# TODO - use systemd managed cgroups


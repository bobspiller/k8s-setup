#!/bin/bash

echo "===== provision-all.sh"

#Versions
K8S_VERSION=1.22.5-00

echo ">>>>> Disable and turn off SWAP ..."
sudo sed -i '/swap/d' /etc/fstab
sudo swapoff -a

echo ">>>>> Stop and Disable firewall ..."
sudo systemctl disable --now ufw

echo ">>>>> Checking of a proxy TLS certificate is configured ..."
if [ -f "/vagrant/config/proxy.crt" ]; then
  echo ">>>>> Installing proxy TLS certificate ..."
  sudo cp /vagrant/config/proxy.crt /usr/local/share/ca-certificates/
  sudo /usr/sbin/update-ca-certificates
fi

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

echo ">>>>> Configuring systemd modules to load for k8s ..."
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
overlay
EOF

echo ">>>>> Configuring systemd modules to load for containerd ..."
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
br_netfilter
overlay
EOF

echo ">>>>> Ensure that iptables can see bridged traffic"
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

echo ">>>>> Apply sysctl parameters without rebooting"
sudo sysctl --system


echo ">>>>> Installing packages required for installing k8s components"
sudo apt-get update
sudo apt-get install -y\
  apt-transport-https\
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

echo ">>>>> Configure containerd to use systemd managed CGroups"
sudo sed -i '/\.containerd\.runtimes\.runc\.options/a\ \ \ \ \ \ \ \ \ \ \ \ SystemdCgroup = true' /etc/containerd/config.toml

echo ">>>>> Adding Google Cloud public signing key"
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg

echo ">>>>> Add kubernetese apt repository"
echo\
  "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main"\
  | sudo tee /etc/apt/sources.list.d/kubernetes.list

echo ">>>>> Update apt package index, install kubelet, kubeadm and kubectl, and pin their version"
sudo apt-get update
sudo apt-get install -y kubelet=${K8S_VERSION} kubeadm=${K8S_VERSION} kubectl=${K8S_VERSION}
sudo apt-mark hold kubelet kubeadm kubectl

echo ">>>>> Update /etc/hosts ..."
sudo tee -a > /dev/null /etc/hosts <<EOF
10.240.10.10  k8s-control-1
10.240.10.11  k8s-node-1
10.240.10.12  k8s-node-2
10.240.10.13  jump
EOF

echo ">>>>> provision-all.sh: done"

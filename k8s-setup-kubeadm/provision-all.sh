#!/bin/bash

echo "===== $0"

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

echo ">>>>> Have kubeadm configure kubelet to use systemd managed CGroups"
cat <<EOF | tee kubeadm-config.yaml
# kubeadm-config.yaml
kind: ClusterConfiguration
apiVersion: kubeadm.k8s.io/v1beta3
kubernetesVersion: v1.21.0
---
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
cgroupDriver: systemd
EOF

echo ">>>>> Adding Google Cloud public signing key"
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg

echo ">>>>> Add kubernetese apt repository"
echo\
  "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main"\
  | sudo tee /etc/apt/sources.list.d/kubernetes.list

echo ">>>>> Update apt package index, install kubelet, kubeadm and kubectl, and pin their version"
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

echo ">>>>> $0: done"

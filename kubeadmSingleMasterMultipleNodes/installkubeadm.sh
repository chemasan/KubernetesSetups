#!/bin/bash

set -e

## Setups Kubeadm along its dependencies Docker and Kubectl ##
## This runs properly on a Debian 10.4 system

# Install Docker pre-requisites
apt-get update
apt-get -y install apt-transport-https ca-certificates curl gnupg-agent software-properties-common

# Docker repository
curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
cat > /etc/apt/sources.list.d/docker.list << EOF
deb [arch=amd64] https://download.docker.com/linux/debian buster stable
# deb-src [arch=amd64] https://download.docker.com/linux/debian buster stable
EOF

# Install Docker packages
apt-get update
apt-get -y install docker-ce docker-ce-cli containerd.io

# Configure cgroups driver for systemd
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
mkdir -p /etc/systemd/system/docker.service.d
systemctl daemon-reload
systemctl restart docker

# Install docker-compose
curl -L "https://github.com/docker/compose/releases/download/1.26.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chown root.root /usr/local/bin/docker-compose && chmod 755 /usr/local/bin/docker-compose
curl -L https://raw.githubusercontent.com/docker/compose/1.26.0/contrib/completion/bash/docker-compose -o /etc/bash_completion.d/docker-compose

# Grant running containers permissions to non-root user 
if [ -n "${SUDO_USER}" ] && [ "${SUDO_USER}" != "root" ]
then
	addgroup "${SUDO_USER}" docker 
fi

# Configure sysctl and iptables
echo br_netfilter > /etc/modules-load.d/br_netfilter.conf
modprobe br_netfilter
cat > /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system

# Disable swap required by kubelet
swapoff -a
sed -i -E 's/^(\S+\s+\S+\s+swap\s+\S+\s+\S+\s+\S+)/#\1/' /etc/fstab

# Install KubeAdm pre-requisites and useful tools
apt-get update
apt-get install -y ebtables ethtool socat conntrack apt-transport-https curl ipvsadm

# Kubernetes repository
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# Configure cgroups driver
mkdir -p /var/lib/kubelet/
cat > /var/lib/kubelet/config.yaml <<EOF
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: systemd
EOF
systemctl daemon-reload

# Install kubectl bash completion and aliases
kubectl completion bash >/etc/bash_completion.d/kubectl
cat > /etc/profile.d/kubectl.sh << EOF
alias k=kubectl
complete -F __start_kubectl k
EOF



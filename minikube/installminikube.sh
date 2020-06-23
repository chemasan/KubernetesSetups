#!/bin/bash

set -e

## Setups Minikube along its dependencies Docker and Kubectl ##
## This runs properly on a Debian 10.4 system

# Install pre-requisites
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

# Install docker-compose
curl -L "https://github.com/docker/compose/releases/download/1.26.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chown root.root /usr/local/bin/docker-compose
chmod 755 /usr/local/bin/docker-compose
curl -L https://raw.githubusercontent.com/docker/compose/1.26.0/contrib/completion/bash/docker-compose -o /etc/bash_completion.d/docker-compose

# Grant running containers permissions to non-root user 
if [ -n "${SUDO_USER}" ] && [ "${SUDO_USER}" != "root" ]
then
	addgroup "${SUDO_USER}" docker 
fi

# Download and install kubectl
curl -L https://storage.googleapis.com/kubernetes-release/release/v1.18.4/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl
chown root.root /usr/local/bin/kubectl
chmod 755 /usr/local/bin/kubectl

# Install bash completion and aliases
kubectl completion bash >/etc/bash_completion.d/kubectl
cat > /etc/profile.d/kubectl.sh << EOF
alias k=kubectl
complete -F __start_kubectl k
EOF

# Install Minikube
curl -L https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 -o /usr/local/bin/minikube
chown root.root /usr/local/bin/minikube
chmod 755 /usr/local/bin/minikube

# Helm repository
curl https://helm.baltorepo.com/organization/signing.asc | apt-key add -
echo "deb https://baltocdn.com/helm/stable/debian/ all main" > /etc/apt/sources.list.d/helm-stable-debian.list
apt-get update
apt-get install -y helm

# Add charts repository 
helm repo add stable https://kubernetes-charts.storage.googleapis.com/
helm repo update

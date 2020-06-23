#!/bin/bash

set -e

## Setup Kubernetes cluster with Kubeadm ##
## This runs properly on a Debian 10.4 system

# Setup the control plane
kubeadm config images pull
kubeadm init --apiserver-advertise-address=192.168.50.10 --control-plane-endpoint=control --pod-network-cidr 10.0.0.0/16

# Configure kubectl
mkdir -p ~/.kube
cp /etc/kubernetes/admin.conf ~/.kube/config
if [ -n "${SUDO_USER}" ] && [ "${SUDO_USER}" != "root" ]
then
	mkdir -p ~${SUDO_USER}/.kube
	cp /etc/kubernetes/admin.conf ~${SUDO_USER}/.kube/config
	chown -R "${SUDO_USER}.${SUDO_USER}" ~${SUDO_USER}/.kube
fi

# Install network pod
#kubectl apply -f https://docs.projectcalico.org/v3.14/manifests/calico.yaml
#kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"

# Wait for networking pods to be up and running
kubectl wait --for='condition=Ready' pod --all=true --namespace=kube-system --timeout=600s

# Done setting control plane
exit 0



# Join new control planes
kubeadm join control:6443 --token 9b3skj.humtj4d3j1d6zcxv --discovery-token-ca-cert-hash sha256:027ab39393db777e150ff1afc176f5717329ae7b398244c810c133d629108da8 --control-plane



# Join worker nodes
kubeadm join control:6443 --token 9b3skj.humtj4d3j1d6zcxv --discovery-token-ca-cert-hash sha256:027ab39393db777e150ff1afc176f5717329ae7b398244c810c133d629108da8


# List existing tokens, on the control plane:
kubeadm token list

# Tokens expires, to create a new token on the control plane:
kubeadm token create

# Get the token CA certificate hash on the control plane:
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'

#TODO
# - dashboard
# - server metrics




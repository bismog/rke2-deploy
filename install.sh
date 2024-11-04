#!/usr/bin/env bash

# Prepare:
# 1. ip and gateway configured
# 2. ssh mutual authentication to all nodes

# This base on rocky linux 9.2
dnf install -y git python-pip
# pip install ansible
pip install --trusted-host mirrors.aliyun.com -i http://mirrors.aliyun.com/pypi/simple ansible

# Check /etc/resolv.conf, make sure right server configured

# Establish ssh mutual trust from first server to other nodes
for node in $(grep rke2_type hosts | awk -F'=' '{print $2}' | awk '{print $1}');do
    cat ~/.ssh/id_ed25519.pub | ssh $node "cat >> ~/.ssh/authorized_keys"
    sed -i -e '/nameserver/d' -e 'a nameserver 1.1.1.1' /etc/resolv.conf
done

read -p"Continue to install(y/n)" answer
if [[ "${answer}x" != "yx" && "${answer}x" != "x" ]];then
    exit 0
fi

# Run deployment
ansible-playbook -i hosts site.yml

# echo "export PATH=\$PATH:/var/lib/rancher/rke2/bin/" >> ~/.bashrc 
if ! grep kubectl ~/.bashrc;then
    tee >> ~/.bashrc <<EOF
alias kubectl='/var/lib/rancher/rke2/bin/kubectl --kubeconfig /etc/rancher/rke2/rke2.yaml'
alias k='kubectl'
EOF
fi

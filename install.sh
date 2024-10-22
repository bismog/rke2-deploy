#!/usr/bin/env bash

# This base on rocky linux 9.2
dnf install -y git python-pip
# pip install ansible
pip install --trusted-host mirrors.aliyun.com -i http://mirrors.aliyun.com/pypi/simple ansible

# Check /etc/resolv.conf, make sure right server configured

# Establish ssh mutual trust from first server to other nodes
for node in $(grep rke2_type hosts | awk -F'=' '{print $2}' | awk '{print $1}');do
    cat ~/.ssh/id_ed25519.pub | ssh $node "cat >> ~/.ssh/authorized_keys"
done

read -p"Continue to install(y/n)" answer
if [[ "${answer}x" != "yx" -a "${answer}x" != "x" ]];then
    exit 0
fi

# Run deployment
ansible-playbook -i hosts site.yml

# echo "export PATH=\$PATH:/var/lib/rancher/rke2/bin/" >> ~/.bashrc 
if ! grep CRI_CONFIG_FILE ~/.bashrc;then
    tee >> ~/.bashrc <<EOF
export CRI_CONFIG_FILE=/var/lib/rancher/rke2/agent/etc/crictl.yaml
alias nerdctl='nerctl -a /run/k3s/containerd/containerd.sock -n k8s.io'
alias kubectl='/var/lib/rancher/rke2/bin/kubectl --kubeconfig /etc/rancher/rke2/rke2.yaml'
alias k='kubectl'
EOF
fi

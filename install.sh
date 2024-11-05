#!/usr/bin/env bash

workdir=$(cd $(dirname $0);pwd)

# Establish ssh mutual trust from first server to other nodes
for node in $(grep rke2_type hosts | awk -F'=' '{print $2}' | awk '{print $1}');do
    cat ~/.ssh/id_ed25519.pub | ssh $node "cat >> ~/.ssh/authorized_keys"
    ssh $node "nmcli con mod bond-mgtbond ipv4.dns 1.1.1.1;nmcli con up bond-mgtbond"
    # check: nmcli -g ipv4.dns connection show bond-mgtbond
    #        cat /etc/resolv.conf
done

# This base on rocky linux 9.2
dnf install -y git python-pip
# pip install ansible
pip install --trusted-host mirrors.aliyun.com -i http://mirrors.aliyun.com/pypi/simple ansible

read -p"Continue to install(y/n)" answer
if [[ "${answer}x" != "yx" && "${answer}x" != "x" ]];then
    exit 0
fi

# Run deployment
ansible-playbook -i hosts site.yml | tee $workdir/ansible.log

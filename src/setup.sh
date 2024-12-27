#!/usr/bin/env bash

workdir=$(cd $(dirname $0);pwd)

node_bin=$(command -v node)
if [[ $? -ne 0 ]];then
    dnf install -y nodejs
fi

mkdir -p /etc/ansible
if [[ ! -e /etc/ansible/hosts ]];then
    cp $workdir/hosts /etc/ansible
fi
if [[ ! -e /etc/ansible/all.yml ]];then
    cp $workdir/group_vars/all.yml /etc/ansible
fi

# node server/server.js
nohup node $workdir/server/server.js > /tmp/server.log 2>&1 &
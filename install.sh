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
if ! rpm -q python3-pip;then
    dnf install -y git python3-pip
fi

if [[ ! -e ~/.pip/pip.conf ]];then
    mkdir -p ~/.pip
    tee ~/.pip/pip.conf <<EOF
[global]
retries=0
index-url=http://mirrors.aliyun.com/pypi/simple/
extra-index-url=
        https://pypi.tuna.tsinghua.edu.cn/simple/
        http://pypi.douban.com/simple
        http://pypi.mirrors.ustc.edu.cn/simple/

[install]
trusted-host=
        mirrors.aliyun.com
        pypi.tuna.tsinghua.edu.cn
        pypi.douban.com
        pypi.mirrors.ustc.edu.cn
EOF
fi
pip install -r requirements.txt

# check list
# iface2 should not in the same CIDR with iface1
# definition in files: hosts and group_vars/all.yml
read -p"Continue to install? (y/n)" answer
if [[ "${answer}x" != "yx" && "${answer}x" != "x" ]];then
    exit 0
fi

# Run deployment
ansible-playbook -i hosts site.yml | tee $workdir/ansible.log

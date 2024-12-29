#!/usr/bin/env bash

workdir=$(cd $(dirname $0);pwd)
hosts_file="/etc/ansible/hosts"
function install() {
    # This base on rocky linux 9.2
    if ! rpm -q python3-pip;then
        dnf install -y sshpass python3-pip
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
    cat > /etc/ansible/ansible.cfg <<EOF
[defaults]
vault_password_file: ~/.vault_pass.txt
EOF
    # 1st 100 digit of 1/pi
    echo -n "0.31830988618379072291434728030056720467402039198650115868386425660588343656381177207211725721909750823377661938578601587124299322306439095522888497312152240832206443235332884881796808452051238079789918" > ~/.vault_pass.txt

    # Establish ssh mutual trust from first server to other nodes
    plain_file=$(mktemp)
    if grep ANSIBLE_VAULT $hosts_file &>/dev/null;then
        ansible-vault view $hosts_file > $plain_file
        encrypted='yes'
    else
        encrypted='no'
        plain_file=$hosts_file
    fi
    for node in $(grep rke2_type $plain_file | awk -F'=' '{print $2}' | awk '{print $1}');do
        passphrase=$(grep $node $plain_file | awk )
        cat ~/.ssh/id_ed25519.pub | sshpass -p $passphrase ssh $node "cat >> ~/.ssh/authorized_keys"
        ssh $node "nmcli con mod bond-mgtbond ipv4.dns 1.1.1.1;nmcli con up bond-mgtbond"
        # check: nmcli -g ipv4.dns connection show bond-mgtbond
        #        cat /etc/resolv.conf
    done
    if [[ "$encrypted" == "yes" ]];then
        rm -f $plain_file 2>/dev/null
    fi
    ansible-vault encrypt $hosts_file

    # check list
    # iface2 should not in the same CIDR with iface1
    # definition in files: hosts and group_vars/all.yml
    # read -p"Continue to install? (y/n)" answer
    # if [[ "${answer}x" != "yx" && "${answer}x" != "x" ]];then
    #     exit 0
    # fi

    # Run deployment
    echo "Begin installation..."
    ansible-playbook -i $hosts_file -e @/etc/ansible/all.yml $workdir/site.yml
}

while :;do
    echo "hello rke2 ..." | tee -a /var/log/install.log
    sleep 10
done
# install 2>&1 | tee /var/log/install.log

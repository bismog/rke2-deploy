#!/usr/bin/env bash

# This base on rocky linux 9.2
dnf install -y git python-pip
pip install ansible

# Check /etc/resolv.conf, make sure right server configured

# Establish ssh mutual trust from first server to other nodes
for node in $(grep rke2_type hosts | awk '{print $1}');do
    cat ~/.ssh/id_ed25519.pub | ssh $node "cat >> ~/.ssh/authorized_keys"
done

# Run deployment
# ansible-playbook -i hosts site.yml

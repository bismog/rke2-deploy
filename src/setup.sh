#!/usr/bin/env bash

workdir=$(cd $(dirname $0);pwd)

if ! rpm -q nodejs;then
    dnf install -y nodejs
fi

node server/server.js
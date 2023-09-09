#!/bin/bash
sudo -i
cat >> /etc/yum.repos.d/otus.repo << EOF
[otus]
name=otus-linux
baseurl=http://192.168.10.10/repos
gpgcheck=0
enabled=1
EOF
#!/bin/bash

sudo -i
yum install -y \
    redhat-lsb-core \
    wget \
    rpmdevtools \
    rpm-build \
    createrepo \
    yum-utils \
    gcc

mkdir -p /usr/share/nginx/html/repo


wget https://nginx.org/packages/centos/7/SRPMS/nginx-1.14.1-1.el7_4.ngx.src.rpm
rpm -i nginx-1.14.1-1.el7_4.ngx.src.rpm
yes | yum-builddep /root/rpmbuild/SPECS/nginx.spec

wget https://www.openssl.org/source/openssl-1.1.1k.tar.gz -O /root/openssl-1.1.1k.tar.gz
mkdir /root/openssl-1.1.1k
tar -xvf /root/openssl-1.1.1k.tar.gz -C /root


mv /root/rpmbuild/RPMS/x86_64/nginx-1.14.1-1.el7_4.ngx.x86_64.rpm /usr/share/nginx/html/repo/
wget https://downloads.percona.com/downloads/percona-release/percona-release-1.0-6/redhat/percona-release-1.0-6.noarch.rpm -O /usr/share/nginx/html/repo/percona-release-0.1-6.noarch.rpm

createrepo /usr/share/nginx/html/repo/

yes | rm -r /home/vagrant/nginx-1.14.1-1.el7_4.ngx.src.rpm
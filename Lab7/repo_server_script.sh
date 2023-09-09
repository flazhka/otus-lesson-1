#!/bin/bash
sudo -i
yum install -y \
    wget \
    nginx \
    createrepo \
    yum-utils 
sed -i 's@index.htm;@index.htm;\n        autoindex on;@g' /root/rpmbuild/SOURCES/nginx.vh.default.conf
systemctl enable nginx --now
mkdir -p /usr/share/nginx/html/repos
wget https://nginx.org/packages/centos/7/SRPMS/nginx-1.14.1-1.el7_4.ngx.src.rpm -O /usr/share/nginx/html/repos/nginx-1.14.1-1.el7_4.ngx.src.rpm
wget https://downloads.percona.com/downloads/percona-release/percona-release-1.0-6/redhat/percona-release-1.0-6.noarch.rpm -O /usr/share/nginx/html/repos/percona-release-0.1-6.noarch.rpm
createrepo -v /usr/share/nginx/html/repos/


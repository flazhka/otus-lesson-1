# Управление пакетами. Дистрибьюция софта 

### Домашнее задание
1) Создать свой RPM пакет (можно взять свое приложение, либо собрать, например, апач с определенными опциями)
2) Создать свой репозиторий и разместить там ранее собранный RPM
3) Реализовать это все либо в Vagrant, либо развернуть у себя через NGINX и датя ссылку на репозиторий

### Создание свого RPM пакета

Сервер репозитория
sudo -i

yum install -y \
    redhat-lsb-core \
    wget \
    rpmdevtools \
    rpm-build \
    createrepo \
    yum-utils \
    gcc

wget https://nginx.org/packages/centos/7/SRPMS/nginx-1.24.0-1.el9.ngx.src.rpm
rpm -i nginx-1.24.0-1.el9.ngx.src.rpm
yes | yum-builddep /root/rpmbuild/SPECS/nginx.spec

wget https://www.openssl.org/source/openssl-1.1.1v.tar.gz -O /root/openssl-1.1.1k.tar.gz  
mkdir /root/openssl-1.1.1v
tar -xvf /root/openssl-1.1.1v.tar.gz -C /root/openssl-1.1.1v/





sed -i 's@index.htm;@index.htm;\n        autoindex on;@g' /root/rpmbuild/SOURCES/nginx.vh.default.conf
sed -i 's@--with-ld-opt="%{WITH_LD_OPT}" @--with-ld-opt="%{WITH_LD_OPT}" \\\n    --with-openssl=/root/openssl-1.1.1k @g' /root/rpmbuild/SPECS/nginx.spec


rpmbuild -bb rpmbuild/SPECS/nginx.spec

ll /root/rpmbuild/RPMS/x86_64/

yum localinstall -y /root/rpmbuild/RPMS/x86_64/nginx-1.24.0-1.el9.ngx.x86_64.rpm

systemctl start nginx

systemctl status nginx

mkdir /usr/share/nginx/html/repo

mv /root/rpmbuild/RPMS/x86_64/nginx-1.24.0-1.el9.ngx.x86_64.rpm /usr/share/nginx/html/repo/
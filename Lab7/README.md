# Управление пакетами. Дистрибьюция софта 

### Домашнее задание
1) Создать свой RPM пакет (можно взять свое приложение, либо собрать, например, апач с определенными опциями)
2) Создать свой репозиторий и разместить там ранее собранный RPM
3) Реализовать это все либо в Vagrant, либо развернуть у себя через NGINX и датя ссылку на репозиторий

Подготовлено 2ва файла для настройки сервера(хранилища репозитория) и настрока для клиента.
В файлах отстуствует час для сборки пакета, только механизм создания репозитория и его публикация.

### Создание сервера с репозиторием
#### Создание свого RPM пакета

Выполним установку патетов:
```sh
[vagrant@rpm ~]$ sudo -i
[root@rpm ~]# yum install -y \
    redhat-lsb-core \
    wget \
    rpmdevtools \
    rpm-build \
    createrepo \
    yum-utils \
    gcc
```
Скачаем NGINX и OpenSSL
```sh
[root@rpm ~]# wget https://nginx.org/packages/centos/9/SRPMS/nginx-1.24.0-1.el9.ngx.src.rpm
[root@rpm ~]# rpm -i nginx-1.24.0-1.el9.ngx.src.rpm
[root@rpm ~]# yes | yum-builddep /root/rpmbuild/SPECS/nginx.spec
[root@rpm ~]# wget https://www.openssl.org/source/openssl-1.1.1v.tar.gz
[root@rpm ~]# tar -xvf openssl-1.1.1v.tar.gz
```
Внесем исправления в spec файл чтобы NGINX собирался с необходимыми опциями  
Выполним сбоку пакета RPM
```sh
Добавим использование openssl в конфиг rpmbuild/SPECS/nginx.spec
    --with-openssl=/root/openssl-1.1.1v
[root@rpm ~]# rpmbuild -bb /root/rpmbuild/SPECS/nginx.spec
```
Убедимся что пакеты создались:
```sh
[root@rpm ~]# ll rpmbuild/RPMS/x86_64/
total 4108
-rw-r--r--. 1 root root 2073021 Sep  9 14:46 nginx-1.24.0-1.el9.ngx.x86_64.rpm
-rw-r--r--. 1 root root 2125972 Sep  9 14:46 nginx-debuginfo-1.24.0-1.el9.ngx.x86_64.rpm
```

Выполним установику пакета и убедимся что nginx работает
```sh
[root@rpm ~]# yum localinstall -y /root/rpmbuild/RPMS/x86_64/nginx-1.24.0-1.el9.ngx.x86_64.rpm
[root@rpm ~]# systemctl enable nginx --now

Installed:
  nginx-1:1.24.0-1.el9.ngx.x86_64
Complete!
```

Создадим  каталог для репозитория и скопируем туда собранный RPM пакет
```sh
[root@rpm ~]# mkdir -p /usr/share/nginx/html/repo
[root@rpm ~]# cp /root/rpmbuild/RPMS/x86_64/nginx-1.24.0-1.el9.ngx.x86_64.rpm /usr/share/nginx/html/repo/

[root@rpm ~]# wget https://downloads.percona.com/downloads/percona-distribution-mysql-ps/percona-distribution-mysql-ps-8.0.33/binary/redhat/9/x86_64/percona-orchestrator-3.2.6-9.el9.x86_64.rpm -O /usr/share/nginx/html/repo/percona-orchestrator-3.2.6-9.el9.x86_64.rpm
```

Выполним создание репозитория
```sh
[root@rpm ~]# createrepo /usr/share/nginx/html/repo/
```

В файле /etc/nginx/conf.d/default.conf добавим директиву autoindex on.
```sh
location / {
root /usr/share/nginx/html;
index index.html index.htm;
autoindex on; Добавили эту директиву
}
```

Проверāем синтаксис и перезапускаем NGINX:
```sh
[root@rpm ~]# nginx -t
[root@rpm ~]# nginx -s reload
```
Проверим работу в репозитория:
```sh
[root@rpm ~]# curl -a http://localhost/repo/

<html>
<head><title>Index of /repo/</title></head>
<body>
<h1>Index of /repo/</h1><hr><pre><a href="../">../</a>
<a href="repodata/">repodata/</a>                                          09-Sep-2023 18:15                   -
<a href="nginx-1.24.0-1.el9.ngx.x86_64.rpm">nginx-1.24.0-1.el9.ngx.x86_64.rpm</a>                  09-Sep-2023 17:52             2073021
<a href="percona-orchestrator-3.2.6-9.el9.x86_64.rpm">percona-orchestrator-3.2.6-9.el9.x86_64.rpm</a>        29-May-2023 10:28             5306801
</pre><hr></body>
</html>
```
Добавим репозиторий в /etc/yum.repos.d:
```sh
[root@rpm ~]# cat >> /etc/yum.repos.d/otus.repo << EOF
> [otus]
name=otus-linux
baseurl=http://localhost/repo
gpgcheck=0
enabled=1
EOF
```

Просмотрим репозиторий и выполним установку из него:
```sh
[root@rpm ~]# yum list | grep otus
nginx 1.24.0 otus
percona-release.noarch 0.1-6 otus
[root@rpm ~]# yum install percona-orchestrator.x86_64 -y
```


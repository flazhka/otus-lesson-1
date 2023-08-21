#  NFS, FUSE
Домашнее задание:
- `vagrant up` должен поднимать 2 настроенных виртуальных машины (сервер NFS и клиента) без дополнительных ручных действий; 
- на сервере NFS должна быть подготовлена и экспортирована директория; 
- в экспортированной директории должна быть поддиректория с именем __upload__ с правами на запись в неё; 
- экспортированная директория должна автоматически монтироваться на клиенте при старте виртуальной машины (systemd, autofs или fstab -  любым способом); 
- монтирование и работа NFS на клиенте должна быть организована с использованием NFSv3 по протоколу UDP; 
- firewall должен быть включен и настроен как на клиенте, так и на сервере. 

### Настраиваем сервер NFS






```
administrator@lablotus01:~/otus_vm/Lab6$ vagrant ssh nfss
[vagrant@nfss ~]$ sudo -i
[root@nfss vagrant]# yum install nfs-utils -y
[root@nfss vagrant]# systemctl enable firewalld --now
[root@nfss vagrant]# firewall-cmd --add-service="nfs3" \
--add-service="rpc-bind" \
--add-service="mountd" \
--permanent 
firewall-cmd --reload
[root@nfss vagrant]# systemctl enable nfs-server
[root@nfss vagrant]# systemctl start nfs-server
[root@nfss vagrant]# ss -tnplu 
[root@nfss vagrant]# mkdir /nfs_share/upload
[root@nfss vagrant]# chmod 0755 /nfs_share
[root@nfss vagrant]# chown root:root /nfs_share
[root@nfss vagrant]# cat << EOF > /etc/exports 
/nfs_share 192.168.10.31(rw,sync,root_squash) 
EOF
[root@nfss vagrant]# exportfs -r 
[root@nfss vagrant]# exportfs -s
[root@nfss vagrant]# 

```

```shell
#!/bin/bash
yum install nfs-utils -y
systemctl enable firewalld --now
systemctl enable nfs-server
systemctl start nfs-server
mkdir /nfs_share
mkdir /nfs_share/upload

exportfs -r 
exportfs -s

```

### Настраиваем клиент NFS
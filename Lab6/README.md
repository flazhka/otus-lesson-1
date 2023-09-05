# NFS, FUSE
#### Домашнее задание:
- `vagrant up` должен поднимать 2 настроенных виртуальных машины (сервер NFS и клиента) без дополнительных ручных действий; 
- на сервере NFS должна быть подготовлена и экспортирована директория; 
- в экспортированной директории должна быть поддиректория с именем __upload__ с правами на запись в неё; 
- экспортированная директория должна автоматически монтироваться на клиенте при старте виртуальной машины (systemd, autofs или fstab -  любым способом); 
- монтирование и работа NFS на клиенте должна быть организована с использованием NFSv3 по протоколу UDP; 
- firewall должен быть включен и настроен как на клиенте, так и на сервере. 


Обнаружил, что у меня, для используемого образа Vagrant "generic/centos9s" отключена опция монтирования nfs шары по udp, убил огромное колличество времени чтобы передать этот параметр ядру и загрузиться так:
```shell
[root@nfsc mnt]# grep -i udp /boot/config-5.14.0-289.el9.x86_64 | grep -i nfs
CONFIG_NFS_DISABLE_UDP_SUPPORT=y
CONFIG_NFS_DISABLE_UDP_SUPPORT=n
```
### Настраиваем сервер NFS
Заходим на сервер 
```shell
vagrant ssh nfss
```
Повышаем привилегии, 
```shell
sudo -i 
```
Устанавливаем утилиты nfs-utils, включаем сервер NFS - __/etc/nfs.conf__ доп настройки
```shell
yum install nfs-utils -y
systemctl enable nfs-server --now 
``` 
Создаём и настраиваем директорию, которая будет экспортирована в будущем 
```shell 
mkdir -p /nfs_share/upload
chown -R root:root /nfs_share
chmod 0766 /nfs_share
touch /nfs_share/upload/test_server_file.txt
chown -R nfsnobody:nfsnobody /nfs_share/upload
```
В файле __/etc/exports__ прописываем список шаренных дирректорий и параметров к ним
```shell
echo "/nfs_share 192.168.10.0/24(rw,sync,no_root_squash,no_all_squash)" >> /etc/exports
exportfs -a
systemctl restart nfs-server
```
Включаем и настраиваем firewalld
```shell 
systemctl enable firewalld --now 
firewall-cmd --permanent --zone=public --add-service={nfs,nfs3,ssh,rpc-bind,mountd}
firewall-cmd --permanent --add-port=2049/udp
firewall-cmd --permanent --add-port=20048/udp
firewall-cmd --reload
``` 

### Настраиваем клиент NFS
Заходим на клиент 
```shell
vagrant ssh nfsс
```
Повышаем привилегии
```shell
sudo -i 
```
Устанавливаем утилиты nfs-utils
```shell
yum -y install nfs-utils autofs
```
Создаем папку
```shell
sudo mkdir -p /nfs_share/
```
Монтируем шару с созданную папку
```shell
mount -t nfs -o proto=udp 192.168.10.30:/nfs_share /nfs_share
```
Создаем 2ва файла с настройками для automount
```shell
echo -e '\n[Unit]' \
        '\nDescription="NFS automount"' \
        '\nRequires=network-online.target' \
        '\nAfter=network-online.service' \
        '\n[Mount]' \
        '\nWhat=192.168.10.30:/nfs_share/' \
        '\nWhere=nfs_share' \
        '\nType=nfs' \
        '\nDirectoryMode=0755' \
        '\nOptions=rw,noatime,noauto,x-systemd.automount,noexec,nosuid,proto=udp,vers=3' \
        '\n[Install]' \
        '\nWantedBy=multi-user.target' \
        '\n' | tee /etc/systemd/system/nfs_share.automount
echo -e '\n[Unit]' \
        '\nDescription="NFS mount"' \
        '\nRequires=network-online.target' \
        '\nAfter=network-online.service' \
        '\n[Automount]' \
        '\nWhere=/nfs_share' \
        '\nTimeoutIdleSec=10' \
        '\n[Install]' \
        '\nWantedBy=multi-user.target' \
        '\n' | tee /etc/systemd/system/mnt-nfs_share.mount
```

Запуск сервиса автомонтирования
```shell
systemctl enable nfs_share.automount
systemctl start nfs_share.automount
```

### Процедура тестирования
Дожидаемся создания виртуальных машин и отработки скриптов.  
Подключаемся к клиентской машине и проверяем начилие файла test_server_file.txt
```shell
vagrant up
```
Подключаемся к клиентской машине и серверной машине и проверяем начилие файла test_server_file.txt
```shell
vagrant ssh nfsc
[vagrant@nfsc ~]$ cd /nfs_share/upload/
[vagrant@nfsc upload]$ ll
[vagrant@nfsc upload]$ vim test_server_file.txt
```

Изменяем файл на клиенте и проверяем изменения на серевере.
```shell
vagrant ssh nfss
[vagrant@nfss ~]$ cd /nfs_share/upload/
[vagrant@nfss upload]$ cat test_server_file.txt
```

Также проверяем и в обратную сторону.
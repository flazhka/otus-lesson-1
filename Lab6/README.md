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
cp /etc/nfs.conf /etc/nfs.conf.bak
sed -i -e 's/# udp=n/udp=y/g' /etc/nfs.conf
systemctl enable --now nfs-server
``` 

Создаём и настраиваем директорию, которая будет экспортирована в будущем 
```shell 
mkdir -p /nfs_share/upload
echo 'Hi, this is test-file, if this file exist and can be changed - nfs server work correctly' | tee /nfsshare/upload/test_nfs_file.txt
chown -R root:root /nfs_share
chmod 0766 /nfs_share
chown -R nfsnobody:nfsnobody /nfs_share/upload
```
В файле __/etc/exports__ прописываем список шаренных дирректорий и параметров к ним
```shell
echo "/nfs_share 192.168.10.31/24(rw,sync,no_wdelay,no_root_squash)" >> /etc/exports
exportfs -a
```
Включаем и настраиваем firewalld
```shell 
systemctl enable firewalld --now 
firewall-cmd --add-service={nfs,nfs3,rpc-bind,mountd} --zone=public --permanent
firewall-cmd --add-port=2049/udp --permanent
firewall-cmd --add-port=20048/udp --permanent
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
yum -y install nfs-utils
```
Создаем папку
```shell
sudo mkdir /nfs_share/
```
Монтируем шару в созданную папку
```shell
cp /etc/fstab /etc/fstab.bak
echo "192.168.10.30:/nfs_share/ /nfs_share/ nfs vers=3,proto=udp,noauto,x-systemd.automount 0 0" >> /etc/fstab #mount -t nfs -o proto=udp 192.168.10.30:/nfs_share /nfs_share
systemctl daemon-reload
systemctl restart remote-fs.target #mount |grep nfs_share, df -h - проверяем корректность монтирования
```

### Процедура тестирования
Выключаем vm, после чего выполняем ключение тачек, дожидаемся создания виртуальных машин и отработки скриптов.  
Подключаемся к клиентской машине и проверяем начилие файла test_server_file.txt
```shell
vagrant up
```
Подключаемся к клиентской машине и серверной машине и проверяем начилие файла test_nfs_file.txt

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
[vagrant@nfss upload]$ vim test_server_file.txt
```
Также проверяем и в обратную сторону возможность изменения файла и его доступность.
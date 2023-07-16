# Файловые системы и LVM - 1

1. Уменьшить том под / до 8G
2. выделить том под /home
3. выделить том под /var (/var - сделать в mirror)
4. для /home - сделать том для снэпшотов
5. прописать монтирование в fstab (попробовать с разными опциями и разными файловыми системами на выбор)
Работа со снапшотами:
сгенерировать файлы в /home/
снять снэпшот
удалить часть файлов
восстановиться со снэпшота
(залоггировать работу можно утилитой script, скриншотами и т.п.)
Задание со звездочкой*
на нашей куче дисков попробовать поставить btrfs/zfs:
с кешем и снэпшотами
разметить здесь каталог /opt
Если возникнут вопросы, обращайтесь к студентам, преподавателям и наставникам в канал группы в Telegram.
Удачи при выполнении!


### Введение в работу с LVM
Для начала необходимо определиться какие устройства мы хотим использовать в качестве Physical Volumes (далее - PV) для наших будущих Volume Groups (далее - VG). Для
этого можно воспользоваться lsblk:  
[root@otuslinux ~]# `lsblk`  
```
NAME MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
sda 8:0 0 40G 0 disk
|-sda1 8:1 0 1M 0 part
|-sda2 8:2 0 1G 0 part /boot
`-sda3 8:3 0 39G 0 part
|-VolGroup00-LogVol00 253:0 0 37.5G 0 lvm /
`-VolGroup00-LogVol01 253:1 0 1.5G 0 lvm [SWAP]
sdb 8:16 0 10G 0 disk
sdc 8:32 0 2G 0 disk
sdd 8:48 0 1G 0 disk
sde 8:64 0 1G 0 disk
```
[root@otuslinux ~]# `lvmdiskscan` # На дисках sdd,sde создадим lvm mirror.  
```
/dev/VolGroup00/LogVol00 [ <37.47 GiB]
/dev/VolGroup00/LogVol01 [ 1.50 GiB]
/dev/sda2 [ 1.00 GiB]
/dev/sda3 [ <39.00 GiB] LVM physical volume
/dev/sdb [ 10.00 GiB]
/dev/sdc [ 2.00 GiB]
/dev/sdd [ 1.00 GiB]
/dev/sde [ 1.00 GiB]
4 disks
3 partitions
0 LVM physical volume whole disks
1 LVM physical volume
```




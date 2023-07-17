# Файловые системы и LVM - 1

1. Уменьшить том под / до 8G
2. выделить том под /home
3. выделить том под /var (/var - сделать в mirror)
4. для /home - сделать том для снэпшотов
5. прописать монтирование в fstab (попробовать с разными опциями и разными файловыми системами на выбор)
Работа со снапшотами:
- сгенерировать файлы в /home/
- снять снэпшот
- удалить часть файлов
- восстановиться со снэпшота (залоггировать работу можно утилитой script, скриншотами и т.п.)
- Задание со звездочкой*
на нашей куче дисков попробовать поставить btrfs/zfs:
с кешем и снэпшотами разметить здесь каталог /opt

## Введение в работу с LVM
Для начала необходимо определиться какие устройства мы хотим использовать в качестве Physical Volumes (далее - PV) для наших будущих Volume Groups (далее - VG). Для
этого можно воспользоваться lsblk:  
[root@otuslinux ~]# `lsblk`  
```
NAME              MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda                 8:0    0  128G  0 disk 
├─sda1              8:1    0    1G  0 part /boot
└─sda2              8:2    0  127G  0 part 
  ├─centos9s-root 253:0    0  125G  0 lvm  /
  └─centos9s-swap 253:1    0    2G  0 lvm  [SWAP]
sdb                 8:16   0    1G  0 disk 
sdc                 8:32   0  512M  0 disk 
sdd                 8:48   0  256M  0 disk 
sde                 8:64   0  256M  0 disk 
```

##### На диска  _sdb, sdc_ - будут развернуты базовые вещи и снапшоты, _sdd, sde_ - lvm mirror.

1) Создадим `Phisical Volume`
```
[vagrant@lvm ~]$ sudo pvcreate /dev/sdb
Physical volume "/dev/sdb" successfully created.
```

2) Создадим `Volume Group`
```
[vagrant@lvm ~]$ sudo vgcreate otus /dev/sdb
Volume group "otus" successfully created
```

3) Создадим `Logical Volume`
```
[vagrant@lvm ~]$ sudo lvcreate -l+80%FREE -n test otus
Logical volume "test" created.
```

4) Вывод информации о созданной `Volume Group`
```
[vagrant@lvm ~]$ sudo vgdisplay otus
--- Volume group ---
VG Name               otus
System ID             
Format                lvm2
Metadata Areas        1
Metadata Sequence No  2
VG Access             read/write
VG Status             resizable
MAX LV                0
Cur LV                1
Open LV               0
Max PV                0
Cur PV                1
Act PV                1
VG Size               1020.00 MiB
PE Size               4.00 MiB
Total PE              255
Alloc PE / Size       204 / 816.00 MiB
Free  PE / Size       51 / 204.00 MiB
VG UUID               5Qo3Sg-RRZz-uMlJ-84YZ-hY4O-IC4y-S3SkPC
```
#Вывод детальной информации о `Volume Group` добавив ключ `-v`
```
[vagrant@lvm ~]$ sudo vgdisplay -v otus | grep 'PV Name'
PV Name               /dev/sdb 
```  
5) Вывод информации о созданной `Logical Volume`
```
[vagrant@lvm ~]$ sudo lvdisplay /dev/otus/test
--- Logical volume ---
LV Path                /dev/otus/test
LV Name                test
VG Name                otus
LV UUID                5yZIKQ-DC7O-Hef6-vf64-HiJW-QuIW-AF6UVy
LV Write Access        read/write
LV Creation host, time lvm, 2023-07-16 20:51:41 +0000
LV Status              available
# open                 0
LV Size                816.00 MiB
Current LE             204
Segments               1
Allocation             inherit
Read ahead sectors     auto
- currently set to     8192
Block device           253:2
```
6) В сжатом виде информацию можно получить командами `pvs`, `vgs`, `lvs`
```
[vagrant@lvm ~]$ sudo pvs
PV         VG   Fmt  Attr PSize    PFree  
/dev/sdb   otus lvm2 a--  1020.00m 204.00m
```
```
[vagrant@lvm ~]$ sudo vgs
VG   #PV #LV #SN Attr   VSize    VFree  
otus   1   1   0 wz--n- 1020.00m 204.00m
```
```
[vagrant@lvm ~]$ sudo lvs
LV   VG   Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
test otus -wi-a----- 816.00m 
```

7) Создадим еще один LV из свободного места, не
экстентами, а абсолютным значением в мегабайтах 
```
[vagrant@lvm ~]$ sudo lvcreate -L 50M -n small otus
Rounding up size to full physical extent 52.00 MiB
Logical volume "small" created.
```
```
[vagrant@lvm ~]$ sudo lvs
LV    VG   Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
small otus -wi-a-----  52.00m                                                    
test  otus -wi-a----- 816.00m  
```
8) Создадим на LV файловую систему и смонтируем его
```
[vagrant@lvm ~]$ sudo mkfs.ext4 /dev/otus/test
mke2fs 1.46.5 (30-Dec-2021)
Creating filesystem with 208896 4k blocks and 52304 inodes
Filesystem UUID: a12c3d4b-592e-4e12-9801-5c8420c49bf6
Superblock backups stored on blocks: 
	32768, 98304, 163840

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done
```
```
[vagrant@lvm ~]$ sudo mkdir /data
[vagrant@lvm ~]$ sudo mount /dev/otus/test /data/
[vagrant@lvm ~]$ mount | grep /data
/dev/mapper/otus-test on /data type ext4 (rw,relatime,seclabel)
```
## LVM Resizing
### Расширение LVM
Допустим встала проблема нехватки свободного места в директории /data. Мы можем расширить файловую систему на LV /dev/otus/test за счет нового блочного устройства
/dev/sdc
```
[vagrant@lvm ~]$ sudo pvcreate /dev/sdc
Physical volume "/dev/sdc" successfully created.
```
1) Расширим VG
```
[vagrant@lvm ~]$ sudo vgextend otus /dev/sdc
Volume group "otus" successfully extended
```
2) Проверим, что появился новый диск и место

```
[vagrant@lvm ~]$ sudo vgdisplay -v otus | grep 'PV Name'
PV Name               /dev/sdb     
PV Name               /dev/sdc     
```
```
[vagrant@lvm ~]$ sudo vgs
VG   #PV #LV #SN Attr   VSize VFree  
otus   2   2   0 wz--n- 1.49g 660.00m
```
3) Сымитируем, что место занято на /data
```
[vagrant@lvm ~]$ sudo dd if=/dev/zero of=/data/test.log bs=1M count=5000 status=progress
789577728 bytes (790 MB, 753 MiB) copied, 9 s, 87.6 MB/s
dd: error writing '/data/test.log': No space left on device
770+0 records in
769+0 records out
806920192 bytes (807 MB, 770 MiB) copied, 9.32804 s, 86.5 MB/s
```
```
[vagrant@lvm ~]$ df -Th /data/
Filesystem            Type  Size  Used Avail Use% Mounted on
/dev/mapper/otus-test ext4  786M  770M     0 100% /data
```
4) Увеличиваем LV за счет появившегося свободного места
```
[vagrant@lvm ~]$ sudo lvextend -l+80%FREE /dev/otus/test
Size of logical volume otus/test changed from 816.00 MiB (204 extents) to 1.31 GiB (336 extents).
Logical volume otus/test successfully resized.
```
5) Наблюдаем что LV расширен до 1.31 GiB:
```
[vagrant@lvm ~]$ sudo lvs /dev/otus/test
LV   VG   Attr       LSize Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
test otus -wi-ao---- 1.31g                                                  
```
6) файловая система при этом осталась прежнего размера, произведем resize файловой системы
```
[vagrant@lvm ~]$ df -Th /data
Filesystem            Type  Size  Used Avail Use% Mounted on
/dev/mapper/otus-test ext4  786M  770M     0 100% /data
```
```
[vagrant@lvm ~]$ sudo resize2fs /dev/otus/test
resize2fs 1.46.5 (30-Dec-2021)
Filesystem at /dev/otus/test is mounted on /data; on-line resizing required
old_desc_blocks = 1, new_desc_blocks = 1
The filesystem on /dev/otus/test is now 344064 (4k) blocks long.
```
```
[vagrant@lvm ~]$ df -Th /data
Filesystem            Type  Size  Used Avail Use% Mounted on
/dev/mapper/otus-test ext4  1.3G  770M  462M  63% /data
```
### Уменьшение LV
Допустим необходимо оставить место на снапшоты. Можно уменьшить существующий LV с помощью lvreduce. 

1) Для этого необходимо отмонтировать файловую систему,
проверить её на ошибки и уменьшить ее размер

```
[vagrant@lvm ~]$ sudo umount /data/
[vagrant@lvm ~]$ sudo e2fsck -fy /dev/otus/test
e2fsck 1.46.5 (30-Dec-2021)
Pass 1: Checking inodes, blocks, and sizes
Pass 2: Checking directory structure
Pass 3: Checking directory connectivity
Pass 4: Checking reference counts
Pass 5: Checking group summary information
/dev/otus/test: 12/82192 files (0.0% non-contiguous), 206882/344064 blocks
```
```
[vagrant@lvm ~]$ sudo resize2fs /dev/otus/test 2G
resize2fs 1.46.5 (30-Dec-2021)
The containing partition (or device) is only 344064 (4k) blocks.
You requested a new size of 524288 blocks.
```

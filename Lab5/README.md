# Практические навыки работы с ZFS
#### Домашнее задание

1. Определить алгоритм с наилучшим сжатием. 
- Определить какие алгоритмы сжатия поддерживает zfs (gzip, zle, lzjb, lz4);  
- Создать 4 файловых системы на каждой применить свой алгоритм сжатия;
- Для сжатия использовать либо текстовый файл, либо группу файлов.
2. Определить настройки пула.
С помощью команды zfs import собрать pool ZFS;
Командами zfs определить настройки:
- размер хранилища;
- тип pool;
- значение recordsize;
- какое сжатие используется;
- какая контрольная сумма используется.   
3. Работа со снапшотами.
скопировать файл из удаленной директории.   https://drive.google.com/file/d/1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG/view?usp=sharing 
восстановить файл локально. zfs receive
найти зашифрованное сообщение в файле secret_message


## Выполнение домашнего задания
### Определить алгоритм с наилучшим сжатием
Смотрим список всех дисков, которые есть в виртуальной машине: `lsblk`
```
agrant@zfs:~$ lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
loop0    7:0    0 63.5M  1 loop /snap/core20/1974
loop1    7:1    0 91.9M  1 loop /snap/lxd/24061
loop2    7:2    0 53.3M  1 loop /snap/snapd/19457
sda      8:0    0  128M  0 disk 
sdb      8:16   0   40G  0 disk 
└─sdb1   8:17   0   40G  0 part /
sdc      8:32   0   10M  0 disk 
sdd      8:48   0  128M  0 disk 
sde      8:64   0  128M  0 disk 
sdf      8:80   0  128M  0 disk 
sdg      8:96   0  128M  0 disk 
sdh      8:112  0  128M  0 disk 
sdi      8:128  0  128M  0 disk 
sdj      8:144  0  128M  0 disk
```
Создаём 4 пула из двух дисков в режиме RAID1:
```
zpool create otus1 mirror /dev/sda /dev/sdd
zpool create otus2 mirror /dev/sde /dev/sdf
zpool create otus3 mirror /dev/sdg /dev/sdh
zpool create otus4 mirror /dev/sdi /dev/sdj
```
Смотрим информацию о пулах: `zpool list`  
```
vagrant@zfs:~$ zpool list
NAME    SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
otus1   112M   104K   112M        -         -     2%     0%  1.00x    ONLINE  -
otus2   112M   132K   112M        -         -     2%     0%  1.00x    ONLINE  -
otus3   112M   104K   112M        -         -     2%     0%  1.00x    ONLINE  -
otus4   112M    96K   112M        -         -     2%     0%  1.00x    ONLINE  -
```
`zpool status` показывает информацию о каждом диске, состоянии сканирования и об ошибках чтения  
`zpool list` показывает информацию о размере пула, количеству занятого и свободного места, дедупликации  

Добавим разные алгоритмы сжатия в каждую файловую систему:
- Алгоритм lzjb: `zfs set compression=lzjb otus1`
- Алгоритм lz4:  `zfs set compression=lz4 otus2`
- Алгоритм gzip: `zfs set compression=gzip-9 otus3`
- Алгоритм zle:  `zfs set compression=zle otus4`

```
vagrant@zfs:~$ zfs get all | grep compression
otus1  compression           lzjb                   local
otus2  compression           lz4                    local
otus3  compression           gzip-9                 local
otus4  compression           zle                    local
```

Добавим файл в каждый из пулов и проверим сжатие:
```
vagrant@zfs:~$ for i in {1..4}; do wget -P /otus$i https://gutenberg.org/cache/epub/2600/pg2600.converter.log; done
```

Проверим, сколько места занимает один и тот же файл в разных пулах и проверим степень сжатия файлов:
```
vagrant@zfs:~$ zfs list
NAME    USED  AVAIL     REFER  MOUNTPOINT
otus1  21.7M  34.3M     21.6M  /otus1
otus2  17.7M  38.3M     17.6M  /otus2
otus3  10.8M  45.2M     10.7M  /otus3
otus4  39.3M  16.7M     39.1M  /otus4
```
```
vagrant@zfs:~$ zfs get all | grep compressratio | grep -v ref
otus1  compressratio         1.81x                  -
otus2  compressratio         2.22x                  -
otus3  compressratio         3.65x                  -
otus4  compressratio         1.00x                  -
```
<u>Таким образом, у нас получается, что алгоритм gzip-9 самый эффективный по сжатию.</u>

### Определение настроек пула  
Загрузим документ:  
`wget -O archive.tar.gz --no-check-certificate 'https://drive.google.com/u/0/uc?id=1KRBNW33QWqbvbVHa3hLJivOAt60yukkg&export=download'`  

и разархивируем его:  
`tar -xzvf archive.tar.gz`  
  
Проверим, возможно ли импортировать данный каталог в пул:
```
vagrant@zfs:~$ sudo zpool import -d zpoolexport/
   pool: otus
     id: 6554193320433390805
  state: ONLINE
 action: The pool can be imported using its name or numeric identifier.
 config:
	otus                                 ONLINE
	  mirror-0                           ONLINE
	    /home/vagrant/zpoolexport/filea  ONLINE
	    /home/vagrant/zpoolexport/fileb  ONLINE
```
Данный вывод показывает имя пула, тип raid и его состав.  

Сделаем импорт `zpool import -d zpoolexport/ otus` данного пула в ОС, a команда `zpool status` выдаст информацию о составе импортированного пула:
```
vagrant@zfs:~$ zpool import -d zpoolexport/ otus
vagrant@zfs:~$ zpool status
```
Выведем все настройки импортированного пула командой: `zpool get all otus`
```
vagrant@zfs:~/zpoolexport$ sudo zpool get all otus
NAME  PROPERTY                       VALUE                          SOURCE
otus  size                           480M                           -
otus  capacity                       0%                             -
otus  altroot                        -                              default
otus  health                         ONLINE                         -
otus  guid                           6554193320433390805            -
otus  version                        -                              default
otus  bootfs                         -                              default
otus  delegation                     on                             default
otus  autoreplace                    off                            default
otus  cachefile                      -                              default
otus  failmode                       wait                           default
otus  listsnapshots                  off                            default
otus  autoexpand                     off                            default
otus  dedupditto                     0                              default
otus  dedupratio                     1.00x                          -
otus  free                           478M                           -
otus  allocated                      2.09M                          -
otus  readonly                       off                            -
otus  ashift                         0                              default
otus  comment                        -                              default
otus  expandsize                     -                              -
otus  freeing                        0                              -
otus  fragmentation                  0%                             -
otus  leaked                         0                              -
otus  multihost                      off                            default
otus  checkpoint                     -                              -
otus  load_guid                      4426313959146398495            -
otus  autotrim                       off                            default
otus  feature@async_destroy          enabled                        local
otus  feature@empty_bpobj            active                         local
otus  feature@lz4_compress           active                         local
otus  feature@multi_vdev_crash_dump  enabled                        local
otus  feature@spacemap_histogram     active                         local
otus  feature@enabled_txg            active                         local
otus  feature@hole_birth             active                         local
otus  feature@extensible_dataset     active                         local
otus  feature@embedded_data          active                         local
otus  feature@bookmarks              enabled                        local
otus  feature@filesystem_limits      enabled                        local
otus  feature@large_blocks           enabled                        local
otus  feature@large_dnode            enabled                        local
otus  feature@sha512                 enabled                        local
otus  feature@skein                  enabled                        local
otus  feature@edonr                  enabled                        local
otus  feature@userobj_accounting     active                         local
otus  feature@encryption             enabled                        local
otus  feature@project_quota          active                         local
otus  feature@device_removal         enabled                        local
otus  feature@obsolete_counts        enabled                        local
otus  feature@zpool_checkpoint       enabled                        local
otus  feature@spacemap_v2            active                         local
otus  feature@allocation_classes     enabled                        local
otus  feature@resilver_defer         enabled                        local
otus  feature@bookmark_v2            enabled                        local
```

Вывести различные параметры пула:  
`zfs get available otus`
```
vagrant@zfs:~/zpoolexport$ sudo zfs get available otus
NAME  PROPERTY   VALUE  SOURCE
otus  available  350M   -
```  
`zfs get readonly otus`
```
vagrant@zfs:~/zpoolexport$ sudo zfs get readonly otus
NAME  PROPERTY  VALUE   SOURCE
otus  readonly  off     default
```
`zfs get recordsize otus`  
```
vagrant@zfs:~/zpoolexport$ sudo zfs get recordsize otus
NAME  PROPERTY    VALUE    SOURCE
otus  recordsize  128K     local
```
`zfs get compression otus`
```
vagrant@zfs:~/zpoolexport$ sudo zfs get compression otus
NAME  PROPERTY     VALUE     SOURCE
otus  compression  zle       local
```
`zfs get checksum otus`
```
vagrant@zfs:~/zpoolexport$ sudo zfs get checksum otus
NAME  PROPERTY  VALUE      SOURCE
otus  checksum  sha256     local
```  

Из вывода следует:  
- размер хранилища = 480M
- тип pool = mirror-0
- значение recordsize = 128K
- какое сжатие используется = zle
- какая контрольная сумма используется = sha256

### Работа со снапшотом, поиск сообщения от преподавателя
Скачаем файл, указанный в задании:  
`wget -O otus_task2.file --no-check-certificate "https://drive.google.com/u/0/uc?id=1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG&export=download"`


Восстановим файловую систему из снапшота:  
`zfs receive otus/test@today < otus_task2.file`

Найдем секретное сообщение:  
```
vagrant@zfs:~$ find /otus/test -name "secret_message"
/otus/test/task1/file_mess/secret_message
```
Прочитаем соощение:  
```
vagrant@zfs:~$ cat /otus/test/task1/file_mess/secret_message
https://github.com/sindresorhus/awesome
```
  
Зашифрованное сообщение - https://github.com/sindresorhus/awesome






















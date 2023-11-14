# Дисковая подсистема, Работа с mdadm

#### Домашнее задание:
- Добавить в Vagrant дополнительные диски
- Собрать R0/R5/R10 raid
- Прописать собранный raid в конфиг, чтобы raid собирался при загрузке системы
- Сломать/починить raid
- Создать GPT раздел и 5 партиций и смонтировать их на диск

### В качестве проверки принимается: 
1. Изменненный Vgrantfile 
2. Скрипт для создания raid
3. Конф файл для автосборки raid при загрузке
4. *Vagrantfile который сразу собирает систему и собирает raid

### Стенд Vagrant
administrator@lablotus01:~$ `vagrant -v`   
vagrant 2.3.7

Начальный стенд взят отсюда: https://github.com/erlong15/otus-linux  

### Добавление в Vagrantfile дополнительного диска
```ruby
:sata5 => {
	:dfile => './sata5.vdi', #Путь по которому будет создан файл диска
	:size => 100, #Размеер диска в мегабайтах
	:port => 5 #Номер порта на который будет подключен диск
}
```

### Сборка RAID 0/1/5/10
Выведем информацию о блочных устройствах установленных в системе.  Это можно сделать нескольким способами:  
- fdisk -l  
- lsblk  
- lshw  
- lsscsi  
   
[vagrant@otuslinux ~]$ `sudo lshw -short | grep disk`  #Вывод информации о присутвующих дисках
```
/0/100/d/0    /dev/sda   disk       137GB VBOX HARDDISK  
/0/100/d/1    /dev/sdb   disk       104MB VBOX HARDDISK  
/0/100/d/2    /dev/sdc   disk       104MB VBOX HARDDISK  
/0/100/d/3    /dev/sdd   disk       104MB VBOX HARDDISK  
/0/100/d/4    /dev/sde   disk       104MB VBOX HARDDISK  
/0/100/d/5    /dev/sdf   disk       104MB VBOX HARDDISK  
```

[vagrant@otuslinux ~]$ `sudo fdisk -l` #Вывод информации о присутвующих дисках

### сборка RAID
Перед созанием raid выполним:  
[vagrant@otuslinux ~]$ `sudo mdadm --zero-superblock --force /dev/sd{b,c,d,e,f}` #Зануление суперблоков  

[vagrant@otuslinux ~]$ `sudo mdadm --create --verbose /dev/md0 -l 5 -n 5 /dev/sd{b,c,d,e,f}` #-l уровень raid -n колличество дисков в raid

[vagrant@otuslinux ~]$ `cat /proc/mdstat` #Вывод информации о RAID массиве
```
Personalities : [raid6] [raid5] [raid4] 
md0 : active raid5 sdf[5] sde[3] sdd[2] sdc[1] sdb[0]
      401408 blocks super 1.2 level 5, 512k chunk, algorithm 2 [5/5] [UUUUU]  #Колличество юнитов в RAID
unused devices: <none>
```

[vagrant@otuslinux ~]$ `sudo mdadm -D /dev/md0`
```
/dev/md0:
           Version : 1.2
     Creation Time : Wed Jul 12 19:09:21 2023
        Raid Level : raid5
        Array Size : 401408 (392.00 MiB 411.04 MB)
     Used Dev Size : 100352 (98.00 MiB 102.76 MB)
      Raid Devices : 5
     Total Devices : 5
       Persistence : Superblock is persistent
       Update Time : Wed Jul 12 19:09:24 2023
             State : clean 
    Active Devices : 5
   Working Devices : 5
    Failed Devices : 0
     Spare Devices : 0
            Layout : left-symmetric
        Chunk Size : 512K #Размер одного чанка
Consistency Policy : resync
              Name : otuslinux:0  (local to host otuslinux)
              UUID : 1ead8b9e:e7060c2f:d4252541:6b7269ca
            Events : 18

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync   /dev/sdb
       1       8       32        1      active sync   /dev/sdc
       2       8       48        2      active sync   /dev/sdd
       3       8       64        3      active sync   /dev/sde
       5       8       80        4      active sync   /dev/sdf
```

### Создание mdadm.conf 
`sudo mdadm --detail --scan --verbose` #Проверка конфигурации raid
```
ARRAY /dev/md0 level=raid5 num-devices=5 metadata=1.2 name=otuslinux:0 UUID=1ead8b9e:e7060c2f:d4252541:6b7269ca
   devices=/dev/sdb,/dev/sdc,/dev/sdd,/dev/sde,/dev/sdf
```

`echo "DEVICE partitions" > /etc/mdadm/mdadm.conf`  
`sudo mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm/mdadm.conf`
```
[vagrant@otuslinux ~]$ cat /etc/mdadm/mdadm.conf 
DEVICE partitions
ARRAY /dev/md0 level=raid5 num-devices=5 metadata=1.2 name=otuslinux:0 UUID=1ead8b9e:e7060c2f:d4252541:6b7269ca
```

### Сломать RAID
`sudo mdadm /dev/md0 --fail /dev/sde` # Перевести диск /dev/sde как ошибочный   
`mdadm -D /dev/md0` или `cat /proc/mdstat` # Вывод информации о RAID массиве  
```
mdadm: set /dev/sde faulty in /dev/md0
```
```
Personalities : [raid6] [raid5] [raid4] 
md0 : active raid5 sdf[5] sde[3](F) sdd[2] sdc[1] sdb[0]
      401408 blocks super 1.2 level 5, 512k chunk, algorithm 2 [5/4] [UUU_U] #4й диск стал ошибочный
```

### Починить RAID
`sudo mdadm /dev/md0 --remove /dev/sde` #Вывести диск sde из raid  
`sudo mdadm /dev/md0 --add /dev/sde` #Добавление нового диска  
#Диск должен пройти процесс rebuild  
`cat /proc/mdstat` #Вывод информации о синхронизации raid
`mdadm -D /dev/md0` # Вывод информации о RAID массиве

### Создание GPT раздела, из 5ти партиций и монтирование к fs
`sudo parted -s /dev/md0 mklabel gpt` #Создаем раздел GPT на созданный RAID   

`sudo parted /dev/md0 mkpart primary ext4 0% 20%`  #Создание партиции  
`sudo parted /dev/md0 mkpart primary ext4 20% 40%`  
`sudo parted /dev/md0 mkpart primary ext4 40% 60%`  
`sudo parted /dev/md0 mkpart primary ext4 60% 80%`  
`sudo parted /dev/md0 mkpart primary ext4 80% 100%`  

`for i in $(seq 1 5); do sudo mkfs.ext4 /dev/md0p$i; done` #Создание fs ext4 на партициях  
`mkdir -p /raid/part{1,2,3,4,5}` #Выполним монтирование  
`for i in $(seq 1 5); do mount /dev/md0p$i /raid/part$i; done`
#В итоге получается:
```
NAME              MAJ:MIN RM  SIZE RO TYPE  MOUNTPOINTS
sda                 8:0    0  128G  0 disk  
├─sda1              8:1    0    1G  0 part  /boot
└─sda2              8:2    0  127G  0 part  
  ├─centos9s-root 253:0    0  125G  0 lvm   /
  └─centos9s-swap 253:1    0    2G  0 lvm   [SWAP]
sdb                 8:16   0  100M  0 disk  
└─md0               9:0    0  392M  0 raid5 
  ├─md0p1         259:0    0 78.4M  0 part  
  ├─md0p2         259:1    0   76M  0 part  
  ├─md0p3         259:2    0   80M  0 part  
  ├─md0p4         259:3    0   78M  0 part  
  └─md0p5         259:4    0   78M  0 part  
sdc                 8:32   0  100M  0 disk  
└─md0               9:0    0  392M  0 raid5 
  ├─md0p1         259:0    0 78.4M  0 part  
  ├─md0p2         259:1    0   76M  0 part  
  ├─md0p3         259:2    0   80M  0 part  
  ├─md0p4         259:3    0   78M  0 part  
  └─md0p5         259:4    0   78M  0 part  
sdd                 8:48   0  100M  0 disk  
└─md0               9:0    0  392M  0 raid5 
  ├─md0p1         259:0    0 78.4M  0 part  
  ├─md0p2         259:1    0   76M  0 part  
  ├─md0p3         259:2    0   80M  0 part  
  ├─md0p4         259:3    0   78M  0 part  
  └─md0p5         259:4    0   78M  0 part  
sde                 8:64   0  100M  0 disk  
└─md0               9:0    0  392M  0 raid5 
  ├─md0p1         259:0    0 78.4M  0 part  
  ├─md0p2         259:1    0   76M  0 part  
  ├─md0p3         259:2    0   80M  0 part  
  ├─md0p4         259:3    0   78M  0 part  
  └─md0p5         259:4    0   78M  0 part  
sdf                 8:80   0  100M  0 disk  
└─md0               9:0    0  392M  0 raid5 
  ├─md0p1         259:0    0 78.4M  0 part  
  ├─md0p2         259:1    0   76M  0 part  
  ├─md0p3         259:2    0   80M  0 part  
  ├─md0p4         259:3    0   78M  0 part  
  └─md0p5         259:4    0   78M  0 part 
```



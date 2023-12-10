# Резервное копирование, настраиваем бэкапы

#### Домашнее задание: 
- Настроить стенд Vagrant с двумя виртуальными машинами: backup_server и client.
- Настроить удаленный бекап каталога /etc c сервера client при помощи borgbackup. 
- Резервные копии должны соответствовать следующим критериям:
    - директория для резервных копий /var/backup. Должна быть отдельная точка монтирования. В данном случае для демонстрации размер не принципиален, достаточно будет и 2GB;
    - репозиторий для резервных копий должен быть зашифрован ключом или паролем - на ваше усмотрение;
    - имя бекапа должно содержать информацию о времени снятия бекапа;
    - глубина бекапа должна быть год, хранить можно по последней копии на конец месяца, кроме последних трех. Последние три месяца должны содержать копии на каждый день. Т.е. должна быть правильно настроена политика удаления старых бэкапов;
    - резервная копия снимается каждые 5 минут. Такой частый запуск в целях демонстрации;
    - написан скрипт для снятия резервных копий. Скрипт запускается из соответствующей Cron джобы, либо systemd timer-а - на ваше усмотрение;
    - настроено логирование процесса бекапа. Для упрощения можно весь вывод перенаправлять в logger с соответствующим тегом. Если настроите не в syslog, то обязательна ротация логов.
    - Запустите стенд на 30 минут.
    - Убедитесь что резервные копии снимаются.
    - Остановите бекап, удалите (или переместите) директорию /etc и восстановите ее из бекапа.
    - Для сдачи домашнего задания ожидаем настроенный стенд, логи процесса бэкапа и описание процесса восстановления.
    - Формат сдачи ДЗ - vagrant + ansible.

#### Выполнение 

1. В качестве стенда будут развернуты 2ве виртуальные машины с 2мя сетевыми картами(разграничить сети).  
Тестовый стенд: 

client-borg Oracle 9  
    - 192.168.50.10 net_backup  
    - 192.168.56.10 main net    
    
server-borg Oracle 9  
    - 192.168.50.20 net_backup  
    - 192.168.56.20 main net  

2. Настройка автоматизации ПО: 
Автоматизация выполнена на основе ролей Ansible для каждого из серверов.

Для всех серовов:  
    -Скопированы пароли и сертификаты для sshd
    -Отключен SELINUX
    -Добавлены ропозитории epel-release
    -Установлено актуальное время
    -Добавлено ПО borgbackup, expect, mc, nano

Для server-borg: 
    - Добавлен новый диск /dev/sdb  
    - Создан новый раздел ext4 /dev/sdb1 и отформатирован в ext4  
    - Добавлен пользователь borg  
    - Создана папка /var/backup и добавлены права для пользователя borg  
    - Выполнено монтирование папки /var/backup к разделу /dev/sdb1  
    - Созданы дирректории с ключами для пользователя borg /home/borg/.ssh authorized_keys

Для client-borg:  
    - Скопированы пароли и сертификаты для sshd  
    - Использованы шаблоны для кастомизации   
        borg-backup_service.j2  
        borg-backup_timer.j2  
        rsyslog_borg_backup_conf.j2  
        ssh_client_config.j2  

3. После запуска развертывания виртуальных машин, будет выполнена инициализиция borg на backup сервере с client сервера (выполняется при помощи скрипта create_repo.sh). После чего создаётся сервис borg-backup.service который в автоматическом режиме бэкапит директорию /etc.

Через некоторое время после развертывания выполним проверку client-borg на наличие бекапа. 

```
vagrant ssh client-borg
sudo -i
borg list borg@192.168.50.20:/var/backup/
```

Информацию о бекапе и размере архива можно посмотреть в логе client-borg `/var/log/borg.log`. Настроено через rsyslog (добавлены соотвествующие строки в borg-backup.service, создан файл конфигурации `/etc/rsyslog.d/borg_backup.conf`).
```
[root@client-borg ~]# cat /var/log/borg.log
Des 1 22:34:46 client-borg borg_backup: ------------------------------------------------------------------------------
Des 1 22:34:46 client-borg borg_backup: Archive name: etc-2023-12-01_22:34:43
Des 1 22:34:46 client-borg borg_backup: Archive fingerprint: bd40d863372d30c895bdd1af8c839c0c10bb37596cee871024b39a8412f08749
Des 1 22:34:46 client-borg borg_backup: Time (start): Fri, 2023-12-01 22:34:44
Des 1 22:34:46 client-borg borg_backup: Time (end):   Fri, 2023-12-01 22:34:46
Des 1 22:34:46 client-borg borg_backup: Duration: 1.69 seconds
Des 1 22:34:46 client-borg borg_backup: Number of files: 1703
Des 1 22:34:46 client-borg borg_backup: Utilization of max. archive size: 0%
Des 1 22:34:46 client-borg borg_backup: ------------------------------------------------------------------------------
Des 1 22:34:46 client-borg borg_backup: Original size      Compressed size    Deduplicated size
Des 1 22:34:46 client-borg borg_backup: This archive:               28.44 MB             13.50 MB             11.85 MB
Des 1 22:34:46 client-borg borg_backup: All archives:               28.44 MB             13.50 MB             11.85 MB
Des 1 22:34:46 client-borg borg_backup: Unique chunks         Total chunks
Des 1 22:34:46 client-borg borg_backup: Chunk index:                    1286                 1702
```

4. Выполним восстановление из бекапа.

Останавливаем службу бекапа.
```
[root@client-borg ~]# systemctl stop borg-backup.timer
```

Выводим информацию о том что находится в бекапе.
```
[root@client-borg ~]# borg list borg@192.168.50.20:/var/backup/
Enter passphrase for key ssh://borg@192.168.50.20/var/backup:
etc-2023-12-01_22:21:16              Fri, 2022-12-01 22:21:17 [02520f9a69005b12c31c1cfb02bdf481dfab58fc640baad4780cdd66ab58ff]

[root@client-borg ~]# borg list borg@192.168.50.20:/var/backup/::etc-2023-12-01_22:34:43 | head - 10
==> standard input <==
Enter passphrase for key ssh://borg@192.168.50.20/var/backup:
drwxr-xr-x root   root          0 Sun, 2022-06-19 15:21:01 etc
-rw------- root   root          0 Fri, 2020-05-01 01:04:55 etc/crypttab
lrwxrwxrwx root   root         17 Fri, 2020-05-01 01:04:55 etc/mtab -> /proc/self/mounts
-rw-r--r-- root   root         12 Sun, 2022-06-19 15:19:05 etc/hostname
-rw-r--r-- root   root       2388 Fri, 2020-05-12 01:08:36 etc/libuser.conf
-rw-r--r-- root   root       2043 Fri, 2020-05-01 01:08:36 etc/login.defs
-rw-r--r-- root   root         37 Fri, 2020-05-01 01:08:36 etc/vconsole.conf
-rw-r--r-- root   root         19 Fri, 2020-05-01 01:08:36 etc/locale.conf
-rw-r--r-- root   root        450 Sun, 2022-06-19 15:19:10 etc/fstab
-rw-r--r-- root   root       1186 Fri, 2021-05-01 01:08:37 etc/passwd
```
Выполняем разархивацию архива.

```
[root@client-borg ~]# borg extract borg@192.168.50.20:/var/backup/::etc-2023-12-01_22:34:43 etc/
Enter passphrase for key ssh://borg@192.168.50.20/var/backup:

[root@client-borg ~]# ls
anaconda-ks.cfg  create_repo.sh  etc  original-ks.cfg

[root@client-borg ~]# ls -l etc/ | wc -l
192
```

Насильно удаляем папку `/etc` на клиенте.
```
[root@client-borg ~]# rm -rf /etc
rm: cannot remove '/etc': Device or resource busy

[root@client-borg ~]# ls /etc/ | wc -l
0
```

Файлов в директории `/etc` не осталось. Выполняем восстанавливаем из ранее скопированного архива файлы обратно.
```
[root@client-borg ~]# cp -Rf etc/* /etc/

[root@client-borg ~]# ls /etc | wc -l
192
```


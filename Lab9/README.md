#  Инициализация системы. Systemd.

#### Домашнее задание:
1) Написать сервис, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова. Файл и слово должны задаваться в /etc/sysconfig.
2) Из epel установить spawn-fcgi и переписать init-скрипт на unit-файл. Имя сервиса должно также называться.
3) Дополнить юнит-файл apache httpd возможностью запустить несколько
инстансов сервера с разными конфигами.

#### 1. Написание сервиса мониторинга
Cоздаём файл с конфигурацией для сервиса в /etc/sysconfig.
```sh
[root@systemd ~]# vim /etc/sysconfig/watchlog
# Configuration file for my watchlog service
# File and word in that file that we will be monit
WORD="ALERT"
LOG=/var/log/watchlog.log
```

Создаем исполняемы скрипт:
```sh
[root@systemd ~]# vim /opt/watchlog.sh
#!/bin/bash
WORD=$1
LOG=$2
DATE=`/bin/date`
if grep $WORD $LOG &> /dev/null;
then
logger "$DATE: I found ALERT, Master!"
else
exit 0
fi
[root@systemd ~]# chmod +x /opt/watchlog.sh
```

Создаем unit-file для сервиса
```sh
[root@systemd ~]# vim /etc/systemd/system/watchlog.service
[Unit]
Description=My watchlog service
[Service]
Type=oneshot
EnvironmentFile=/etc/sysconfig/watchlog
ExecStart=/opt/watchlog.sh $WORD $LOG
```

Создаем unit-file для таймера
```sh
[root@systemd ~]# vim /etc/systemd/system/watchlog.timer
[Unit]
Description=Run watchlog script every 30 second
[Timer]
OnUnitActiveSec=30
Unit=watchlog.service
[Install]
WantedBy=multi-user.target
```

Создаем log-file /var/log/watchlog.log, добавляем ключевое слово ‘ALERT’.
```sh
[root@systemd ~]# vim /var/log/watchlog.log
bsadsa822bdb
asdas2uuu2fcc
Al2ertdfdsfii
Alertdsfsdf
asdsdsadsd
ALERT
DSdsadsadsds
dskjhkkaf
ghsVVvr4444444dfh
```

Затем запускаем timer
```sh
systemctl daemon-reload
systemctl start watchlog.timer #systemctl status watchlog.timer
tail -f /var/log/messages
```

```
[root@systemd ~]# tail -f /var/log/messages
Sep 20 06:24:16 systemd systemd[1]: Starting My watchlog service...
Sep 20 06:24:16 systemd root[6536]: Wed Sep 20 06:24:16 AM UTC 2023: I found ALERT, Master!
Sep 20 06:24:16 systemd systemd[1]: watchlog.service: Deactivated successfully.
Sep 20 06:24:16 systemd systemd[1]: Finished My watchlog service.
Sep 20 06:24:56 systemd systemd[1]: Starting My watchlog service...
Sep 20 06:24:56 systemd root[6550]: Wed Sep 20 06:24:56 AM UTC 2023: I found ALERT, Master!
Sep 20 06:24:56 systemd systemd[1]: watchlog.service: Deactivated successfully.
Sep 20 06:24:56 systemd systemd[1]: Finished My watchlog service.
Sep 20 06:24:56 systemd systemd[1]: Starting Hostname Service...
Sep 20 06:24:56 systemd systemd[1]: Started Hostname Service.
```

#### 2. Написание сервиса (Вообще не понял, что это! нет описания, что за сервис)
Устанавливаем spawn-fcgi и необходимые для него пакеты
```sh
yum install epel-release -y && yum install spawn-fcgi php php-climod_fcgid httpd -y
```

Раскомментируем строки с переменные в /etc/sysconfig/spawn-fcgi
```sh
[root@nginx ~#] cat /etc/sysconfig/spawn-fcgi
# You must set some working options before the "spawn-fcgi" service will work.
# If SOCKET points to a file, then this file is cleaned up by the init script.
#
# See spawn-fcgi(1) for all possible options.
# Example :
SOCKET=/var/run/php-fcgi.sock
OPTIONS="-u apache -g apache -s $SOCKET -S -M 0600 -C 32 -F 1 -- /usr/bin/php-cgi"
```

Создаем unit-file
```sh
[root@nginx ~#] cat /etc/systemd/system/spawn-fcgi.service
{Unit]
Description=Spawn-fcgi startup service by Otus
After=network.target
[Service]
Type=simple
PIDFile=/var/run/spawn-fcgi.pid
EnvironmentFile=/etc/sysconfig/spawn-fcgi
ExecStart=/usr/bin/spawn-fcgi -n \$OPTIONS
KillMode=process
[Install]
WantedBy=multi-user.target
```

Перезапускаем демон, запускаем службу, проверяем ее статус
systemctl daemon-reload
systemctl start spawn-fcgi
systemctl status spawn-fcgi


#### 3. Дополнить юнит файл - возможностью запустить несколько инстансов 
Для примера возъмем шаблон /usr/lib/systemd/system/httpd.service


Add line to httpd.service
```sh
[Unit]
Description=The Apache HTTP Server
Wants=httpd-init.service

After=network.target remote-fs.target nss-lookup.target httpd-
init.service

Documentation=man:httpd.service(8)

[Service]
Type=notify
Environment=LANG=C
EnvironmentFile=/etc/sysconfig/httpd-%I # Add line
ExecStart=/usr/sbin/httpd $OPTIONS -DFOREGROUND
ExecReload=/usr/sbin/httpd $OPTIONS -k graceful
# Send SIGWINCH for graceful stop
KillSignal=SIGWINCH
KillMode=mixed
PrivateTmp=true

[Install]
WantedBy=multi-user.target
```

Создаем 2ва файла окружения с разными конфигурациями
```sh
touch /etc/sysconfig/httpd-first
OPTIONS=-f conf/first.conf

touch /etc/sysconfig/httpd-second
OPTIONS=-f conf/second.conf

Copy httpd config files
cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/first.conf
cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/second.conf
```

В конфигурационных файлах должны бытþ указаны уникальные для каждого экземпляра опции Listen и PidFile.
```sh
PidFile /var/run/httpd-second.pid
sed -i 's/80/8080/g' /etc/httpd/conf/second.conf
```

Перезагрузить units and запустить 2 инстанса httpd сервиса
```sh
systemctl daemon-reload
systemctl start httpd@first httpd@second
systemctl status httpd@first
systemctl status httpd@second

ss -tnulp | grep httpd
```
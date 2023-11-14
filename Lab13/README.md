# SELinux - когда все запрещено 

#### Домашнее задание:
Диагностировать проблемы и модифицировать политики SELinux для корректной работы приложений, если это требуется.
Описание домашнего задания
1. Запустить nginx на нестандартном порту 3-мя разными способами:
переключатели setsebool;
добавление нестандартного порта в имеющийся тип;
формирование и установка модуля SELinux.
К сдаче:
README с описанием каждого решения (скриншоты и демонстрация приветствуются). 

2. Обеспечить работоспособность приложения при включенном selinux.
развернуть приложенный стенд https://github.com/mbfx/otus-linux-adm/tree/master/selinux_dns_problems; 
выяснить причину неработоспособности механизма обновления зоны (см. README);
предложить решение (или решения) для данной проблемы;
выбрать одно из решений для реализации, предварительно обосновав выбор;
реализовать выбранное решение и продемонстрировать его работоспособность

## 1. Запустить nginx на нестандартном порту 3-мя разными способами
!Была обнаружена ошибка при запуске Vagrantfile.  
    
Создал Vagrantfile согласно представленному в методичке по домашнему заданию. В процессе создания ВМ selinux появилась ошибка SELinux, не позволяющая перевести работу nginx на нестандартный порт.
```
selinux: Job for nginx.service failed because the control process exited with error code. See "systemctl status nginx.service" and "journalctl -xe" for details.
```
Был доустановлен пакет: policycoreutils-python.

2. Проверил отключенный firewalld и корректность конфигов nginx.
```
[root@selinux ~]# systemctl status firewalld
● firewalld.service - firewalld - dynamic firewall daemon
   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; disabled; vendor preset: enabled)
   Active: inactive (dead)
     Docs: man:firewalld(1)

[root@selinux ~]# nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

3. Проверил режим работы SELinux: getenforce.
```
[root@selinux ~]# getenforce
 Enforcing
```
В режим Enforcing - SELinux будет блокировать всю запрещенную активность.

#### Способ 1. Разрешим в SELinux работу nginx на порту TCP 4881 c помощью переключателей setsebool
1. Нашел в логах (/var/log/audit/audit.log) информацию о блокировании порта.
```
[root@selinux ~]# less /var/log/audit/audit.log | grep 4881
type=AVC msg=audit(1699189310.904:824): avc:  denied  { name_bind } for  pid=2855 comm="nginx" src=4881 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:unreserved_port_t:s0 tclass=tcp_socket permissive=0
```
2. При помощи утилиты audit2why нашел причину блокировки.
```
[root@selinux ~]# grep 1699189310.904:824 /var/log/audit/audit.log | audit2why 
type=AVC msg=audit(1699189310.904:824): avc:  denied  { name_bind } for  pid=2855 comm="nginx" src=4881 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:unreserved_port_t:s0 tclass=tcp_socket permissive=0
	Was caused by:
	The boolean nis_enabled was set incorrectly. 
	Description:
	Allow nis to enabled
	Allow access by executing:
	# setsebool -P nis_enabled 1
```
Утилита audit2why показывает почему трафик блокируется. Исходя из вывода утилиты нужно поменять параметр nis_enabled.

3. Включил параметр nis_enabled, перезапустил nginx, проверил статус.
```
[root@selinux ~]# setsebool -P nis_enabled on
[root@selinux ~]# systemctl restart nginx
[root@selinux ~]# systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: active (running) since Sun 2023-11-05 13:39:24 UTC; 8s ago
  Process: 22017 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 22014 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
  Process: 22013 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 22019 (nginx)
   CGroup: /system.slice/nginx.service
           ├─22019 nginx: master process /usr/sbin/nginx
           └─22020 nginx: worker process

Nov 05 13:39:24 selinux systemd[1]: Starting The nginx HTTP and reverse proxy server...
Nov 05 13:39:24 selinux nginx[22014]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Nov 05 13:39:24 selinux nginx[22014]: nginx: configuration file /etc/nginx/nginx.conf test is s...sful
Nov 05 13:39:24 selinux systemd[1]: Started The nginx HTTP and reverse proxy server.
Hint: Some lines were ellipsized, use -l to show in full.
```
4. Выполнена проверка nginx из браузера. Переходим по адресу http://10.0.2.15:4881. В выводе страница преветсивя "Welcom to CentOS"  

5. Выпол проверку состояния параметра nis_enabled. Выполнил возврат настройки обратно. После возврата настройки служба nginx снова не запускается.
```
[root@selinux ~]# getsebool -a | grep nis_enabled
nis_enabled --> on
[root@selinux ~]# setsebool -P nis_enabled off
[root@selinux ~]# getsebool -a | grep nis_enabled
nis_enabled --> off
```
#### Способ 2. Разрешим в SELinux работу nginx на порту TCP 4881 c помощью добавления нестандартного порта в имеющийся тип
1. Выполнил поиск имеющегося типа, для http трафика.
```
[root@selinux ~]# semanage port -l | grep http
http_cache_port_t              tcp      8080, 8118, 8123, 10001-10010
http_cache_port_t              udp      3130
http_port_t                    tcp      80, 81, 443, 488, 8008, 8009, 8443, 9000
pegasus_http_port_t            tcp      5988
pegasus_https_port_t           tcp      5989
```

2. Добавил порт 4881 в тип http_port_t, перезапустил nginx.
```
[root@selinux ~]# semanage port -a -t http_port_t -p tcp 4881
[root@selinux ~]# semanage port -l | grep  http_port_t
http_port_t                    tcp      4881, 80, 81, 443, 488, 8008, 8009, 8443, 9000
pegasus_http_port_t            tcp      5988
```
```
[root@selinux ~]# systemctl restart nginx
[root@selinux ~]# systemctl status nginx

● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: active (running) since Sun 2023-11-05 14:09:38 UTC; 1s ago
  Process: 22091 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 22089 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
  Process: 22087 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)

 Main PID: 22094 (nginx)
   CGroup: /system.slice/nginx.service
           ├─22094 nginx: master process /usr/sbin/nginx
           └─22095 nginx: worker process

Nov 05 14:09:38 selinux systemd[1]: Starting The nginx HTTP and reverse proxy server...
Nov 05 14:09:38 selinux nginx[22089]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Nov 05 14:09:38 selinux nginx[22089]: nginx: configuration file /etc/nginx/nginx.conf test is s...sful
Nov 05 14:09:38 selinux systemd[1]: Started The nginx HTTP and reverse proxy server.
```
3. Выполнена проверка nginx из браузера. Переходим по адресу http://10.0.2.15:4881. В выводе страница преветсивя "Welcom to CentOS".

4. Вернул настройки, удалил нестандартный порт из имеющегося типа с помощью команды.
```
[root@selinux ~]# semanage port -d -t http_port_t -p tcp 4881
[root@selinux ~]# semanage port -l | grep  http_port_t
http_port_t                    tcp      80, 81, 443, 488, 8008, 8009, 8443, 9000
pegasus_http_port_t            tcp      5988
```
5. После возврата настройки служба nginx снова не запускается.
```
[root@selinux ~]# systemctl restart nginx
Job for nginx.service failed because the control process exited with error code. See "systemctl status nginx.service" and "journalctl -xe" for details.
[root@selinux ~]# systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: failed (Result: exit-code) since Sun 2023-11-05 14:18:26 UTC; 1min 44s ago
  Process: 22091 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 22120 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 22094 (code=exited, status=0/SUCCESS)
Nov 05 14:18:26 selinux systemd[1]: Stopped The nginx HTTP and reverse proxy server.
Nov 05 14:18:26 selinux systemd[1]: Starting The nginx HTTP and reverse proxy server...
```
#### Способ 3. Разрешим в SELinux работу nginx на порту TCP 4881 c помощью формирования и установки модуля SELinux

1. Попробуем снова запустить nginx. Nginx не запуститься, так как SELinux продолжает его блокировать.
```
[root@selinux ~]# systemctl start nginx
Job for nginx.service failed because the control process exited with error code. See "systemctl status nginx.service" and "journalctl -xe" for details.
```
2. Посмотрим логи SELinux, которые относятся к nginx.
[root@selinux ~]# grep nginx /var/log/audit/audit.log
```
...
type=SERVICE_START msg=audit(1699193906.388:955): pid=1 uid=0 auid=4294967295 ses=4294967295 subj=system_u:system_r:init_t:s0 msg='unit=nginx comm="systemd" exe="/usr/lib/systemd/systemd" hostname=? addr=? terminal=? res=failed'

type=AVC msg=audit(1699194162.350:956): avc:  denied  { name_bind } for  pid=22134 comm="nginx" src=4881 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:unreserved_port_t:s0 tclass=tcp_socket permissive=0

type=SYSCALL msg=audit(1699194162.350:956): arch=c000003e syscall=49 success=no exit=-13 a0=6 a1=5617a4fb3878 a2=10 a3=7ffda7b18f70 items=0 ppid=1 pid=22134 auid=4294967295 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=(none) ses=4294967295 comm="nginx" exe="/usr/sbin/nginx" subj=system_u:system_r:httpd_t:s0 key=(null)

type=SERVICE_START msg=audit(1699194162.354:957): pid=1 uid=0 auid=4294967295 ses=4294967295 subj=system_u:system_r:init_t:s0 msg='unit=nginx comm="systemd" exe="/usr/lib/systemd/systemd" hostname=? addr=? terminal=? res=failed'
```

3. Воспользуемся утилитой audit2allow для того, чтобы на основе логов SELinux сделать модуль, разрешающий работу nginx на нестандартном порту.
```
[root@selinux ~]# grep nginx /var/log/audit/audit.log | audit2allow -M nginx
******************** IMPORTANT ***********************
To make this policy package active, execute:

semodule -i nginx.pp
```

4. Audit2allow сформировал модуль, и сообщил нам команду, с помощью которой можно применить данный модуль: semodule -i nginx.pp
```
[root@selinux ~]# semodule -i nginx.pp
```
5. Снова выполнил запуск nginx.
```
[root@selinux ~]# systemctl restart nginx
[root@selinux ~]# systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: active (running) since Sun 2023-11-05 14:32:25 UTC; 6s ago
  Process: 22163 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 22161 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
  Process: 22160 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 22165 (nginx)
   CGroup: /system.slice/nginx.service
           ├─22165 nginx: master process /usr/sbin/nginx
           └─22166 nginx: worker process

Nov 05 14:32:25 selinux systemd[1]: Starting The nginx HTTP and reverse proxy server...
Nov 05 14:32:25 selinux nginx[22161]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Nov 05 14:32:25 selinux nginx[22161]: nginx: configuration file /etc/nginx/nginx.conf test is s...sful
Nov 05 14:32:25 selinux systemd[1]: Started The nginx HTTP and reverse proxy server.
```
6. Вывел информацию по модулям.
```
[root@selinux ~]# semodule -l | grep nginx
nginx	1.0
```

7. Выполнил удаление модуля.
```
[root@selinux ~]# semodule -r nginx
libsemanage.semanage_direct_remove_key: Removing last nginx module (no other nginx module exists at another priority).
```
8. После удаления модуля nginx снова не запускается.
```
[root@selinux ~]# systemctl restart nginx
Job for nginx.service failed because the control process exited with error code. See "systemctl status nginx.service" and "journalctl -xe" for details.

[root@selinux ~]# systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: failed (Result: exit-code) since Sun 2023-11-05 14:37:19 UTC; 3s ago
  Process: 22163 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 22188 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=1/FAILURE)
  Process: 22187 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 22165 (code=exited, status=0/SUCCESS)
Nov 05 14:37:18 selinux systemd[1]: Starting The nginx HTTP and reverse proxy server...
Nov 05 14:37:19 selinux nginx[22188]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Nov 05 14:37:19 selinux nginx[22188]: nginx: [emerg] bind() to 0.0.0.0:4881 failed (13: Permiss...ied)
Nov 05 14:37:19 selinux nginx[22188]: nginx: configuration file /etc/nginx/nginx.conf test failed
Nov 05 14:37:19 selinux systemd[1]: nginx.service: control process exited, code=exited status=1
Nov 05 14:37:19 selinux systemd[1]: Failed to start The nginx HTTP and reverse proxy server.
Nov 05 14:37:19 selinux systemd[1]: Unit nginx.service entered failed state.
Nov 05 14:37:19 selinux systemd[1]: nginx.service failed.
```
## 2. Обеспечить работоспособность приложения при включенном selinux.
1. Выполнил клонирование репозитория.
administrator@lablotus01:~/otus_vm/Lab13$ git clone https://github.com/mbfx/otus-linux-adm.git

Cloning into 'otus-linux-adm'...
remote: Enumerating objects: 558, done.
remote: Counting objects: 100% (456/456), done.
remote: Compressing objects: 100% (303/303), done.
remote: Total 558 (delta 125), reused 396 (delta 74), pack-reused 102
Receiving objects: 100% (558/558), 1.38 MiB | 1015.00 KiB/s, done.
Resolving deltas: 100% (140/140), done.

2. Перешел в каталог со стендом: cd otus-linux-adm/selinux_dns_problems.  
Развернул 2 виртуальные машины ns01 и client, с помощью vagrant: vagrant up  
После того, как стенд развернулся, провериа ВМ с помощью команды: vagrant status

3. Создал виртуальные машины ns01 и client, склонированные с репозитория. Выполнил проверку состояния vm.
```
administrator@lablotus01:~/otus_vm/Lab13/otus-linux-adm/selinux_dns_problems$ vagrant status

Current machine states:
ns01                      running (virtualbox)
client                    running (virtualbox)
```
4. На клиенте попробовал внести изменения в зону, получил сл. ошибку.
```
administrator@lablotus01:~/otus_vm/Lab13/otus-linux-adm/selinux_dns_problems$ vagrant ssh client
###############################
### Welcome to the DNS lab! ###
###############################
...

[vagrant@client ~]$ nsupdate -k /etc/named.zonetransfer.key 
> 192.168.50.10
incorrect section name: 192.168.50.10
> server 192.168.50.10
> zone ddns.lab
> update add www.ddns.lab. 60 A 192.168.50.15
> send
update failed: SERVFAIL
> quit
```
5. Выполнил проверку логов audit на client, логи отсутствуют.
```
[vagrant@client ~]$ sudo -i
[root@client ~]# cat /var/log/audit/audit.log | audit2why
```
6. Выполнил подключение к серверу ns01 и проверил логи.
```
administrator@lablotus01:~/otus_vm/Lab13/otus-linux-adm/selinux_dns_problems$ vagrant ssh ns01
[vagrant@ns01 ~]$ sudo -i 
[root@ns01 ~]# cat /var/log/audit/audit.log | grep dns

type=AVC msg=audit(1667662732.397:1902): avc:  denied  { create } for  pid=5095 comm="isc-worker0000" name="named.ddns.lab.view1.jnl" scontext=system_u:system_r:named_t:s0 tcontext=system_u:object_r:etc_t:s0 tclass=file permissive=0
```
7. Убедился, что контексты безопасности не совпадают.
```
 [root@ns01 ~]# ls -laZ /etc/named
drw-rwx---. root named system_u:object_r:etc_t:s0       .
drwxr-xr-x. root root  system_u:object_r:etc_t:s0       ..
drw-rwx---. root named unconfined_u:object_r:etc_t:s0   dynamic
-rw-rw----. root named system_u:object_r:etc_t:s0       named.50.168.192.rev
-rw-rw----. root named system_u:object_r:etc_t:s0       named.dns.lab
-rw-rw----. root named system_u:object_r:etc_t:s0       named.dns.lab.view1
-rw-rw----. root named system_u:object_r:etc_t:s0       named.newdns.lab
```

8. Посмотрел в каком каталоги должны лежать, файлы, чтобы на них распространялись правильные политики SELinux.
```
[root@ns01 ~]# sudo semanage fcontext -l | grep named
/etc/rndc.*              regular file       system_u:object_r:named_conf_t:s0 
/var/named(/.*)?         all files          system_u:object_r:named_zone_t:s0 
...
```
9. Поменял контекст безопасности на корректный и убедился, что контекст безопасности корректный.
```
[root@ns01 ~]# chcon -R -t named_zone_t /etc/named
[root@ns01 ~]# ls -laZ /etc/named
drw-rwx---. root named system_u:object_r:named_zone_t:s0 .
drwxr-xr-x. root root  system_u:object_r:etc_t:s0       ..
drw-rwx---. root named unconfined_u:object_r:named_zone_t:s0 dynamic
-rw-rw----. root named system_u:object_r:named_zone_t:s0 named.50.168.192.rev
-rw-rw----. root named system_u:object_r:named_zone_t:s0 named.dns.lab
-rw-rw----. root named system_u:object_r:named_zone_t:s0 named.dns.lab.view1
-rw-rw----. root named system_u:object_r:named_zone_t:s0 named.newdns.lab
```
9. Пробую снова внести изменения с клиента. Обновление зоны прошло успешно.
```
[root@client ~]# nsupdate -k /etc/named.zonetransfer.key 
> server 192.168.50.10
> zone ddns.lab
> update add www.ddns.lab. 60 A 192.168.50.15
> send
> quit

[root@client ~]# dig www.ddns.lab
; <<>> DiG 9.11.4-P2-RedHat-9.11.4-26.P2.el7_9.10 <<>> www.ddns.lab
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 8855
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 1, ADDITIONAL: 2
;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;www.ddns.lab.                  IN      A
;; ANSWER SECTION:
www.ddns.lab.           60      IN      A       192.168.50.15
;; AUTHORITY SECTION:
ddns.lab.               3600    IN      NS      ns01.dns.lab.
;; ADDITIONAL SECTION:
ns01.dns.lab.           3600    IN      A       192.168.50.10
;; Query time: 1 msec
;; SERVER: 192.168.50.10#53(192.168.50.10)
;; WHEN: Sat Nov 05 16:12:08 UTC 2022
;; MSG 
```
10. Перезапустил, настройки сохранились.
[root@client ~]# dig @192.168.50.10 www.ddns.lab
; <<>> DiG 9.11.4-P2-RedHat-9.11.4-26.P2.el7_9.15 <<>> @192.168.50.10 www.ddns.lab
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 12484
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 1
;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;www.ddns.lab.			IN	A
;; AUTHORITY SECTION:
ddns.lab.		600	IN	SOA	ns01.dns.lab. root.dns.lab. 2711201407 3600 600 86400 600

;; Query time: 5 msec
;; SERVER: 192.168.50.10#53(192.168.50.10)
;; WHEN: Sun Nov 05 21:11:29 UTC 2023
;; MSG SIZE  rcvd: 91

11. Причина неработоспособности механизма заключалась в том, что SELinux блокировал доступ к обновлению файлов на сервере ns01 для DNS, а также к некоторым файлам, к которым DNS обращается в процессе работы. Данную проблему можно решить двумя способами:

 - Поменять контекст безопасности (было продемонстрировано)
 - С помошью audit2allow создать разрешающий модуль (Не безопастно)
 - Отключение SELinux (Не безопастно)















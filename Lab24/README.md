#  DNS - настройка и обслуживание 

#### Домашнее задание: 

1. Взять стенд https://github.com/erlong15/vagrant-bind  
- Добавить еще один сервер client2  
- Завести в зоне dns.lab имена:  
    web1 - смотрит на клиент1  
    web2  смотрит на клиент2  
- Завести еще одну зону newdns.lab  
- Завести в ней запись www - смотрит на обоих клиентов

2. Настроить split-dns
- клиент1 - видит обе зоны, но в зоне dns.lab только web1
- клиент2 видит только dns.lab

#### Решение:  
После скачивания проекта и разъархивации:
- Установлены дополнительные пакеты для удобства работы,
- была выполнена растройка NTP клиентов на серверах:
```sh
#Настройка одинакового времени с помощью NTP
  - name: stop and disable chronyd
    service: name=chronyd state=stopped enabled=no
  - name: start and enable ntpd
    service: name=ntpd state=started enabled=yes
```

Согласно задания: 
- client1 должен видеть две настроенные зоны - dns.lab и newdns.lab в зоне dns.lab видеть только A запись web1. 
- client2 должен видеть обе A записи - web1 и web2, однако зона newdns.lab ему должна быть не доступна.  

Для выполнения задания, была создана дополнительная зона - аналогичную dns.lab, из которой была убрана A запись web2. Был создан отдельный файл зоны - named.dns.lab.client.  

После этого сгенерированы 2 ключа для хостов client и client2 с помощью команды tsig-keygen.  

Далее в конфигурационных файлах DNS серверов сделаны разграничение с помощью так называемых настроек view, которые делают match по acl - где описывается клиент и его ключ.  

Был скорректирован файл /etc/resolv.conf для DNS-серверов:  
- ns01 - 192.168.50.10
- ns02 - 192.168.50.11 
В шаблоном с Jinja изменено имя файла servers-resolv.conf на servers-resolv.conf.j2 и указаны следующие настройки:
```sh
administrator@lablotus01:~/otus_vm/Lab24/vagrant-bind/provisioning# cp servers-resolv.conf servers-resolv.conf.j2
administrator@lablotus01:~/otus_vm/Lab24/vagrant-bind/provisioning# vim servers-resolv.conf.j2
administrator@lablotus01:~/otus_vm/Lab24/vagrant-bind/provisioning# cat servers-resolv.conf.j2

domain dns.lab
search dns.lab
#Если имя сервера ns02, то указываем nameserver 192.168.50.11
{% if ansible_hostname == 'ns02' %}
nameserver 192.168.50.11
{% endif %}
#Если имя сервера ns01, то указываем nameserver 192.168.50.10
{% if ansible_hostname == 'ns01' %}
nameserver 192.168.50.10
{% endif %}
```

После внесение измений,  измения добавлены в playbook:
```sh
#Копирование файла resolv.conf
  - name: copy resolv.conf to the servers
    template: src=servers-resolv.conf.j2 dest=/etc/resolv.conf owner=root group=root mode=0644
```

#### Добавление имён в зону dns.lab:

На хосте ns01 в файл /etc/named/named.dns.lab былы добавлены имена клиентов. 
```sh
;Web
web1            IN      A       192.168.50.15
web2            IN      A       192.168.50.16
```

Выполняем роль ansible, подклчючаемся к клиенту и проверяем:
```sh
[vagrant@client ~]$ dig @192.168.50.10 web1.dns.lab
...
;; ANSWER SECTION:
web1.dns.lab.           3600    IN      A       192.168.50.15
...

[vagrant@client ~]$ dig @192.168.50.11 web2.dns.lab
...
;; ANSWER SECTION:
web2.dns.lab.           3600    IN      A       192.168.50.16
...
```

#### Добавление новой зоны на DNS-серверах:  

- хост ns01, добавить зону в файл /etc/named.conf. Он же файл provisioning/master-named.conf копируемый на сервер ns01, который далее отправим на сервер ns01:
```sh
// lab's newdns zone
zone "newdns.lab" {
    type master;
    allow-transfer { key "zonetransfer.key"; };
    allow-update { key "zonetransfer.key"; };
    file "/etc/named/named.newdns.lab";
};
```

- хосте ns02, также добавить зону и указать с какого сервера запрашивать информацию об этой зоне (фрагмент файла /etc/named.conf). Он же файл provisioning/slave-named.conf, который далее отправим на сервер ns02:
```sh
// lab's newdns zone
zone "newdns.lab" {
    type slave;
    masters { 192.168.50.10; };
    file "/etc/named/named.newdns.lab";
};
```

Далее на хосте ns01 создадим файл /etc/named/named.newdns.lab. В конце этого файла добавим записи www. У файла должны быть права 660, владелец — root, группа — named. Относительно ansible это файл provisioning/named.newdns.lab, который далее быдет отправлен на сервер ns01:
```sh
;WWW
www             IN      A       192.168.50.15
www             IN      A       192.168.50.16
```

Добавим в модуль copy файл named.newdns.lab:
```sh
  - name: copy zones
    copy:
      src: "{{ item }}"
      dest: /etc/named/
      owner: root
      group: named
      mode: 0660
    with_fileglob:
      - named.d*
      - named.newdns.lab
```

#### Настройка Split-DNS:
Зоны dns.lab и newdns.lab уже созданы, но по заданию client1 должен видеть запись web1.dns.lab и не видеть запись web2.dns.lab. 

А Client2 может видеть обе записи из домена dns.lab, но не должен видеть записи домена newdns.lab.  
Осуществить данные настройки нам поможет технология Split-DNS. 

Для настройки Split-DNS нужно cоздать дополнительный файл зоны dns.lab, в котором будет прописана только одна запись.  

```sh
administrator@lablotus01:~/otus_vm/Lab24/vagrant-bind# vi provisioning/named.dns.lab.client
$TTL 3600
$ORIGIN dns.lab.
@               IN      SOA     ns01.dns.lab. root.dns.lab. (
                            2711201408 ; serial
                            3600       ; refresh (1 hour)
                            600        ; retry (10 minutes)
                            86400      ; expire (1 day)
                            600        ; minimum (10 minutes)
                        )

                IN      NS      ns01.dns.lab.
                IN      NS      ns02.dns.lab.

; DNS Servers
ns01            IN      A       192.168.50.10
ns02            IN      A       192.168.50.11

;Web
web1            IN      A       192.168.50.15
```

Прежде всего нужно сделать access листы для хостов client и client2.  
Сначала сгенерируем ключи для хостов client и client2, для этого на хосте ns01 запустим утилиту tsig-keygen 2 раза.  
Далее вносим изменения в файл master-named.conf, который скопируем на сервер ns01 в /etc/named.conf.  
Вносим изменения в файл slave-named.conf, который скопируем на сервер ns02 в /etc/named.conf.  

Проверка на client:
```sh
[root@client ~]# ping www.newdns.lab
PING www.newdns.lab (192.168.50.15) 56(84) bytes of data.
64 bytes from client (192.168.50.15): icmp_seq=1 ttl=64 time=0.396 ms
64 bytes from client (192.168.50.15): icmp_seq=2 ttl=64 time=0.033 ms
^C
--- www.newdns.lab ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1001ms
rtt min/avg/max/mdev = 0.033/0.214/0.396/0.182 ms
[root@client ~]# ping web1.dns.lab
PING web1.dns.lab (192.168.50.15) 56(84) bytes of data.
64 bytes from client (192.168.50.15): icmp_seq=1 ttl=64 time=0.020 ms
64 bytes from client (192.168.50.15): icmp_seq=2 ttl=64 time=0.028 ms
^C
--- web1.dns.lab ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1001ms
rtt min/avg/max/mdev = 0.020/0.024/0.028/0.004 ms
[root@client ~]# ping web2.dns.lab
ping: web2.dns.lab: Name or service not known
```

На хосте видим, что client видит обе зоны (dns.lab и newdns.lab), однако информацию о хосте web2.dns.lab он получить не может.  

Проверка на client2:
```sh
[root@client2 ~]# ping www.newdns.lab
ping: www.newdns.lab: Name or service not known
[root@client2 ~]# ping web1.dns.lab
PING web1.dns.lab (192.168.50.15) 56(84) bytes of data.
64 bytes from 192.168.50.15 (192.168.50.15): icmp_seq=1 ttl=64 time=3.43 ms
64 bytes from 192.168.50.15 (192.168.50.15): icmp_seq=2 ttl=64 time=1.33 ms
^C
--- web1.dns.lab ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1002ms
rtt min/avg/max/mdev = 1.332/2.385/3.439/1.054 ms
[root@client2 ~]# ping web2.dns.lab
PING web2.dns.lab (192.168.50.16) 56(84) bytes of data.
64 bytes from client2 (192.168.50.16): icmp_seq=1 ttl=64 time=0.022 ms
64 bytes from client2 (192.168.50.16): icmp_seq=2 ttl=64 time=0.027 ms
^C
--- web2.dns.lab ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1002ms
rtt min/avg/max/mdev = 0.022/0.024/0.027/0.005 ms
```
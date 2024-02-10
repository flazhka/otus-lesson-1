#  Сетевые пакеты. VLAN'ы. LACP 

#### Домашнее задание: 
в Office1 в тестовой подсети появляется сервера с доп. интерфесами и адресами
в internal сети testLAN: 
- testClient1 - 10.10.10.254
- testClient2 - 10.10.10.254
- testServer1- 10.10.10.1 
- testServer2- 10.10.10.1

Равести вланами:
testClient1 <-> testServer1
testClient2 <-> testServer2

Между centralRouter и inetRouter "пробросить" 2 линка (общая inernal сеть) и объединить их в бонд, проверить работу c отключением интерфейсов

#### Решение:  


#### LACP
Был сконфигурирован стенд со следующей потологией:  
![Стенд](https://github.com/flazhka/otuslab-homework/blob/master/Lab25/1.png)


После запуска стенда выполняем проверку - как собрался bonding и его работоспособность.  Подключаемся к одному из серверов - inetRouter и ставим ping второго участника bonding - centralRouter (192.168.255.2), а на втором centralRouter в это время тушим один из интерфейсов, который участвует в bonding - например eth1.


```sh
[root@inetRouter ~]# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 52:54:00:4d:77:d3 brd ff:ff:ff:ff:ff:ff
    inet 10.0.2.15/24 brd 10.0.2.255 scope global noprefixroute dynamic eth0
       valid_lft 85014sec preferred_lft 85014sec
    inet6 fe80::5054:ff:fe4d:77d3/64 scope link
       valid_lft forever preferred_lft forever
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast master team0 state UP group default qlen 1000
    link/ether 08:00:27:b1:5b:44 brd ff:ff:ff:ff:ff:ff
    inet6 fe80::a00:27ff:feb1:5b44/64 scope link
       valid_lft forever preferred_lft forever
4: eth2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast master team0 state UP group default qlen 1000
    link/ether 08:00:27:dd:e7:26 brd ff:ff:ff:ff:ff:ff
    inet6 fe80::a00:27ff:fedd:e726/64 scope link
       valid_lft forever preferred_lft forever
5: eth3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 08:00:27:49:df:90 brd ff:ff:ff:ff:ff:ff
    inet 192.168.56.10/24 brd 192.168.56.255 scope global noprefixroute eth3
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:fe49:df90/64 scope link
       valid_lft forever preferred_lft forever
6: team0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 08:00:27:b1:5b:44 brd ff:ff:ff:ff:ff:ff
    inet 192.168.255.1/24 brd 192.168.255.255 scope global team0
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:feb1:5b44/64 scope link
       valid_lft forever preferred_lft forever
```

```sh
[root@centralRouter ~]# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 52:54:00:4d:77:d3 brd ff:ff:ff:ff:ff:ff
    inet 10.0.2.15/24 brd 10.0.2.255 scope global noprefixroute dynamic eth0
       valid_lft 85638sec preferred_lft 85638sec
    inet6 fe80::5054:ff:fe4d:77d3/64 scope link
       valid_lft forever preferred_lft forever
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast master team0 state UP group default qlen 1000
    link/ether 08:00:27:cc:21:b3 brd ff:ff:ff:ff:ff:ff
    inet6 fe80::a00:27ff:fecc:21b3/64 scope link
       valid_lft forever preferred_lft forever
4: eth2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast master team0 state UP group default qlen 1000
    link/ether 08:00:27:39:c2:5f brd ff:ff:ff:ff:ff:ff
    inet6 fe80::a00:27ff:fe39:c25f/64 scope link
       valid_lft forever preferred_lft forever
5: eth3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 08:00:27:7e:58:0b brd ff:ff:ff:ff:ff:ff
    inet6 fe80::a00:27ff:fe7e:580b/64 scope link
       valid_lft forever preferred_lft forever
6: eth4: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 08:00:27:f8:8e:bd brd ff:ff:ff:ff:ff:ff
    inet 192.168.56.11/24 brd 192.168.56.255 scope global noprefixroute eth4
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:fef8:8ebd/64 scope link
       valid_lft forever preferred_lft forever
10: team0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 08:00:27:cc:21:b3 brd ff:ff:ff:ff:ff:ff
    inet 192.168.255.2/24 brd 192.168.255.255 scope global team0
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:fecc:21b3/64 scope link
       valid_lft forever preferred_lft forever
11: vlan100@eth3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 08:00:27:7e:58:0b brd ff:ff:ff:ff:ff:ff
    inet6 fe80::a00:27ff:fe7e:580b/64 scope link
       valid_lft forever preferred_lft forever
12: vlan101@eth3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 08:00:27:7e:58:0b brd ff:ff:ff:ff:ff:ff
    inet6 fe80::a00:27ff:fe7e:580b/64 scope link
```

Видим - bond собрался.
```sh
[root@inetRouter ~]# ping 192.168.255.2
PING 192.168.255.2 (192.168.255.2) 56(84) bytes of data.
64 bytes from 192.168.255.2: icmp_seq=1 ttl=64 time=0.515 ms
64 bytes from 192.168.255.2: icmp_seq=2 ttl=64 time=0.716 ms
64 bytes from 192.168.255.2: icmp_seq=3 ttl=64 time=0.791 ms
64 bytes from 192.168.255.2: icmp_seq=4 ttl=64 time=0.753 ms
64 bytes from 192.168.255.2: icmp_seq=5 ttl=64 time=0.661 ms
64 bytes from 192.168.255.2: icmp_seq=6 ttl=64 time=0.612 ms
64 bytes from 192.168.255.2: icmp_seq=7 ttl=64 time=0.683 ms
64 bytes from 192.168.255.2: icmp_seq=8 ttl=64 time=0.726 ms
64 bytes from 192.168.255.2: icmp_seq=9 ttl=64 time=0.652 ms
64 bytes from 192.168.255.2: icmp_seq=10 ttl=64 time=0.519 ms
64 bytes from 192.168.255.2: icmp_seq=11 ttl=64 time=0.562 ms
^C
--- 192.168.255.2 ping statistics ---
11 packets transmitted, 11 received, 0% packet loss, time 10026ms
rtt min/avg/max/mdev = 0.515/0.653/0.791/0.093 ms
```
```sh
[root@centralRouter ~]# ip a | grep eth1
3: eth1: <BROADCAST,MULTICAST> mtu 1500 qdisc pfifo_fast state DOWN group default qlen 1000
[root@centralRouter ~]# ifup eth1
```

Из вывода выше видно - bond отработал и соединение не порвалось.

#### VLAN

Выше есть вывод команды ip с сервера centralRouter, у которого на порту eth3 были настроены два VLAN - vlan100@eth3 и vlan101@eth3. Это так называемый trunk порт.  

Так как по условию задачи адресации на svi (vlan интерфейсе) на centralRouter нет, то маршрутизации между vlan 100 и 101 не будет, и в обоих vlan могут нормально существовать сервера с одинаковой адресацией.  

Сервера testClient1 и testServer1 будут находится во vlan 100, а testClient2 и testServer2 будут находится во vlan 101.  

Чтобы проверить - рассмотрим vlan 100 (во vlan 101 - аналогичная ситуация). С сервера testClient1 запустим ping 10.10.10.254 (testServer1), а затем запустим ping 10.10.10.251 - не существующего сервера, и посмотрим что у нас попадёт в tcpdump на centralRouter.

```sh
[root@testClient1 ~]# ping 10.10.10.254
PING 10.10.10.254 (10.10.10.254) 56(84) bytes of data.
64 bytes from 10.10.10.254: icmp_seq=1 ttl=64 time=0.762 ms
64 bytes from 10.10.10.254: icmp_seq=2 ttl=64 time=0.587 ms
64 bytes from 10.10.10.254: icmp_seq=3 ttl=64 time=0.621 ms
^C
--- 10.10.10.254 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2002ms
rtt min/avg/max/mdev = 0.587/0.656/0.762/0.081 ms
[root@testClient1 ~]# ping 10.10.10.251
PING 10.10.10.251 (10.10.10.251) 56(84) bytes of data.
From 10.10.10.1 icmp_seq=1 Destination Host Unreachable
From 10.10.10.1 icmp_seq=2 Destination Host Unreachable
From 10.10.10.1 icmp_seq=3 Destination Host Unreachable
From 10.10.10.1 icmp_seq=4 Destination Host Unreachable
^C
--- 10.10.10.251 ping statistics ---
5 packets transmitted, 0 received, +4 errors, 100% packet loss, time 4001ms
pipe 4

[root@centralRouter ~]# tcpdump -i vlan100
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on vlan100, link-type EN10MB (Ethernet), capture size 262144 bytes
17:27:28.893744 ARP, Request who-has 10.10.10.254 tell 10.10.10.1, length 46
17:27:37.371979 ARP, Request who-has 10.10.10.251 tell 10.10.10.1, length 46
17:27:38.370811 ARP, Request who-has 10.10.10.251 tell 10.10.10.1, length 46
17:27:39.372482 ARP, Request who-has 10.10.10.251 tell 10.10.10.1, length 46
17:27:41.373600 ARP, Request who-has 10.10.10.251 tell 10.10.10.1, length 46
17:27:42.375017 ARP, Request who-has 10.10.10.251 tell 10.10.10.1, length 46
17:27:43.376520 ARP, Request who-has 10.10.10.251 tell 10.10.10.1, length 46
^C
7 packets captured
7 packets received by filter
0 packets dropped by kernel
```

Из вывода tcpdump видно, что как testClient1 ищет broadcast запросом - кто 10.10.10.254, и найдя его пакеты уже идут к серверу testServer1 и он не попадает в вывод tcpdump
```
17:27:28.893744 ARP, Request who-has 10.10.10.254 tell 10.10.10.1, length 46
```
А когда пингуем не существующий ip адрес, то так как адресат не откликнулся - каждый пакет и будет broadcast и будет попадать в tcpdump на любом сервере в данном vlan.
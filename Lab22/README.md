# Статическая и динамическая маршрутизация, OSPF_OSPF

#### Домашнее задание: 
1. Развернуть 3 виртуальные машины
2. Объединить их разными vlan
- настроить OSPF между машинами на базе Quagga;
- изобразить ассиметричный роутинг;
- сделать один из линков "дорогим", но что бы при этом роутинг был симметричным.

#### Решение: 

OSPF — протокол динамической маршрутизации, использующий концепцию разделения на области в целях масштабирования.  
Административная дистанция OSPF — 110

Основные свойства протокола OSPF:  
- Быстрая сходимость  
- Масштабируемость (подходит для маленьких и больших сетей)
- Безопасность (поддежка аутентиикации)
- Эффективность (испольование алгоритма поиска кратчайшего пути)

Протоколы OSPF бвывают 2-х версий:  
- OSPFv2 (работает с IPv4)
- OSPFv3 (работает с IPv6)    

Internal router (внутренний маршрутизатор) — маршрутизатор, все интерфейсы которого находятся в одной и той же области.  

Backbone router (магистральный маршрутизатор) — это маршрутизатор, который находится в магистральной зоне (area 0).  

ABR (пограничный маргрутизатор области) — маршрутизатор, интерфейсы которого подключены к разным областям.  

ASBR (Граничный маршрутизатор автономной системы) — это маршрутизатор, у которого интерфейс подключен к внешней сети.  

1. Разворачиваем 3 виртуальные машины, сеть будет иметь сл. топологию.

![Архитектура сети](https://github.com/flazhka/otuslab-homework/blob/master/Lab22/1.png)

Настройка OSPF осуществляется на основе FRR. Установка данного пакета, настройка конфигурации серверов осуществляется с помощью ansible, согласно инструкциям, описанным в методичке. После  запуска vagrant стенда у нас разворачиваются три виртуальных серверах, с сетевой конфигурацией показанной на схеме.  


![Архитектура сети](https://github.com/flazhka/otuslab-homework/blob/master/Lab22/2.png)


2. Настройка OSPF между vm на базе Quagga.

Проверяем, что демон OSPF запущен и работает корректно, все  роутеры обменялись информацией о своих сетях.  

Проверку будем выполнена с frr роутеров через `vtysh`.

*Router1* - проверяем таблицу маршрутизции OSPF.  

```sh
vagrant@router1:~$ sudo -i
root@router1:~# vtysh

Hello, this is FRRouting (version 8.2.2).
Copyright 1996-2005 Kunihiro Ishiguro, et al.

router1# sh ip ospf route
============ OSPF network routing table ============
N    10.0.10.0/30          [100] area: 0.0.0.0
                           directly attached to enp0s8
N    10.0.11.0/30          [200] area: 0.0.0.0
                           via 10.0.10.2, enp0s8
                           via 10.0.12.2, enp0s9
N    10.0.12.0/30          [100] area: 0.0.0.0
                           directly attached to enp0s9
N    192.168.10.0/24       [100] area: 0.0.0.0
                           directly attached to enp0s10
N    192.168.20.0/24       [200] area: 0.0.0.0
                           via 10.0.10.2, enp0s8
N    192.168.30.0/24       [200] area: 0.0.0.0
                           via 10.0.12.2, enp0s9

============ OSPF router routing table =============

============ OSPF external routing table ===========
```

- Пробуем сделать ping и traceroute до сети 192.168.30.0/24, которая передаётся в OSPF с router3.

```sh
router1# ping 192.168.30.1
PING 192.168.30.1 (192.168.30.1) 56(84) bytes of data.
64 bytes from 192.168.30.1: icmp_seq=1 ttl=64 time=0.302 ms
64 bytes from 192.168.30.1: icmp_seq=2 ttl=64 time=0.455 ms
^C
--- 192.168.30.1 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1032ms
rtt min/avg/max/mdev = 0.477/0.559/0.642/0.082 ms

router1# traceroute 192.168.30.1
traceroute to 192.168.30.1 (192.168.30.1), 30 hops max, 60 byte packets
 1  192.168.30.1 (192.168.30.1)  0.725 ms  0.644 ms  0.590 ms
```

OSPF работает, маршрутизация была настроена с помощью OSPF.  

- Теперь проверим, как изменится маршрут до этой же сети, если мы отключим прямой линк между `router1` и `router3`. Для этого на router1 отключим интерфейс enp0s9 (либо enp0s9 на router3) и посмотрим ещё раз traceroute.

```sh
router1# sh int br
Interface       Status  VRF             Addresses
---------       ------  ---             ---------
enp0s3          up      default         10.0.2.15/24
enp0s8          up      default         10.0.10.1/30
enp0s9          up      default         10.0.12.1/30
enp0s10         up      default         192.168.10.1/24
enp0s16         up      default         192.168.56.10/24
lo              up      default

router1# conf t
router1(config)# int enp0s9
router1(config-if)# shutdown
router1(config-if)# do traceroute 192.168.30.1
traceroute to 192.168.30.1 (192.168.30.1), 30 hops max, 60 byte packets
 1  10.0.10.2 (10.0.10.2)  0.576 ms  0.452 ms  0.370 ms
 2  192.168.30.1 (192.168.30.1)  0.911 ms  0.868 ms  0.822 ms
router1(config-if)# no shutdown
```

Из вывода traceroute можно сделать вывод - что OSPF отработал и трафик пошёл через второй маршрут, через router2.

3. Настройка ассиметричного роутинга

Для проверки асимметричного роутинга, выполню настройку стоимость интерфейса enp0s8 на router1 - 1000.  

Таким образом, маршруты до других роутеров, в том числе router2 - станут менее приоритетными через данный интерфейс (чем меньше cost - тем приоритетней маршрут).  

- В файле main.yml изменим значение переменной symmetric_routing с empty на false. 
- Далее выполню запуск playbook, но с указание только тега - `setup_ospf`.
- Также в конфигурацию серверов были внесены изменения, чтобы разрешить ассиметричный трафик - `sysctl net.ipv4.conf.all.rp_filter=0`.

```sh
administrator@lablotus01:~/otus_vm/Lab22/Ansible$ ansible-playbook provision.yml -t setup_ospf

router1# show ip route ospf
Codes: K - kernel route, C - connected, S - static, R - RIP,
       O - OSPF, I - IS-IS, B - BGP, E - EIGRP, N - NHRP,
       T - Table, v - VNC, V - VNC-Direct, A - Babel, F - PBR,
       f - OpenFabric,
       > - selected route, * - FIB route, q - queued, r - rejected, b - backup
       t - trapped, o - offload failure

O   10.0.10.0/30 [110/300] via 10.0.12.2, enp0s9, weight 1, 00:19:04
O>* 10.0.11.0/30 [110/200] via 10.0.12.2, enp0s9, weight 1, 00:19:09
O   10.0.12.0/30 [110/100] is directly connected, enp0s9, weight 1, 00:19:09
O   192.168.10.0/24 [110/100] is directly connected, enp0s10, weight 1, 00:19:44
O>* 192.168.20.0/24 [110/300] via 10.0.12.2, enp0s9, weight 1, 00:19:04
O>* 192.168.30.0/24 [110/200] via 10.0.12.2, enp0s9, weight 1, 00:19:09

router2# sh ip route ospf
Codes: K - kernel route, C - connected, S - static, R - RIP,
       O - OSPF, I - IS-IS, B - BGP, E - EIGRP, N - NHRP,
       T - Table, v - VNC, V - VNC-Direct, A - Babel, F - PBR,
       f - OpenFabric,
       > - selected route, * - FIB route, q - queued, r - rejected, b - backup
       t - trapped, o - offload failure

O   10.0.10.0/30 [110/100] is directly connected, enp0s8, weight 1, 00:20:34
O   10.0.11.0/30 [110/100] is directly connected, enp0s9, weight 1, 00:20:34
O>* 10.0.12.0/30 [110/200] via 10.0.10.1, enp0s8, weight 1, 00:19:59
  *                        via 10.0.11.1, enp0s9, weight 1, 00:19:59
O>* 192.168.10.0/24 [110/200] via 10.0.10.1, enp0s8, weight 1, 00:19:59
O   192.168.20.0/24 [110/100] is directly connected, enp0s10, weight 1, 00:20:34
O>* 192.168.30.0/24 [110/200] via 10.0.11.1, enp0s9, weight 1, 00:19:59
```

После изменения конфигурации на router1 проверяем, как маршрутизируются пакеты, зарустив ping.

```sh
root@router1:~# ping -I 192.168.10.1 192.168.20.1
PING 192.168.20.1 (192.168.20.1) from 192.168.10.1 : 56(84) bytes of data.
64 bytes from 192.168.20.1: icmp_seq=1 ttl=64 time=1.03 ms
64 bytes from 192.168.20.1: icmp_seq=2 ttl=64 time=1.09 ms
```

На router2 запускаем tcpdump, для контроля трафика на порту `enp0s9`.

```sh 
root@router2:~# tcpdump -i enp0s9
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on enp0s9, link-type EN10MB (Ethernet), capture size 262143 bytes
19:48:08.369899 ARP, Request who-has router2 tell 10.0.11.1, length 46
19:48:08.369899 IP 192.168.10.1 > router2: ICMP echo request, id 4, seq 16, length 64
19:48:08.369959 ARP, Reply router2 is-at 08:00:27:e4:07:56 (oui Unknown), length 28
19:48:09.371279 IP 192.168.10.1 > router2: ICMP echo request, id 4, seq 17, length 64
19:48:10.372952 IP 192.168.10.1 > router2: ICMP echo request, id 4, seq 18, length 64
19:48:10.495043 IP router2 > ospf-all.mcast.net: OSPFv2, Hello, length 48
19:48:10.495274 IP 10.0.11.1 > ospf-all.mcast.net: OSPFv2, Hello, length 48
19:48:11.374760 IP 192.168.10.1 > router2: ICMP echo request, id 4, seq 19, length 64
19:48:12.376756 IP 192.168.10.1 > router2: ICMP echo request, id 4, seq 20, length 64
19:48:13.378698 IP 192.168.10.1 > router2: ICMP echo request, id 4, seq 21, length 64
^C
10 packets captured
10 packets received by filter
0 packets dropped by kernel
```

На router2 запускаем tcpdump, для контроля трафика на порту `enp0s8`.

```sh
root@router2:~# tcpdump -i enp0s8
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on enp0s8, link-type EN10MB (Ethernet), capture size 262144 bytes
19:49:02.523377 IP router2 > 192.168.10.1: ICMP echo reply, id 4, seq 70, length 64
19:49:03.525920 IP router2 > 192.168.10.1: ICMP echo reply, id 4, seq 71, length 64
19:49:04.527641 IP router2 > 192.168.10.1: ICMP echo reply, id 4, seq 72, length 64
19:49:05.529465 IP router2 > 192.168.10.1: ICMP echo reply, id 4, seq 73, length 64
19:49:06.531983 IP router2 > 192.168.10.1: ICMP echo reply, id 4, seq 74, length 64
19:49:07.537088 IP router2 > 192.168.10.1: ICMP echo reply, id 4, seq 75, length 64
19:49:08.539562 IP router2 > 192.168.10.1: ICMP echo reply, id 4, seq 76, length 64
^C
7 packets captured
7 packets received by filter
0 packets dropped by kernel
```

Из вывода видно, что icmp пакет приходит через `enp0s9` с `router3`, а уходит на enp0s8 на router1. Это является ассиметричным роутингом, который по `default` запрещён.

4. Настройка симметичного роутинга

Для того, чтобы сделать роутинг симметричным, необходимо выровнять cost на direct-link между `router1` и `router2`. То есть на `router2` также на интерфейсе enp0s8 выставить cost 1000.  

Для этого, необходимо в файле main.yml изменить значение переменной `symmetric_routing` с `false` на `true`.  
После этого запустим playbook, но с указание только тега - `setup_ospf`.


```sh
administrator@lablotus01:~/otus_vm/Lab22/Ansible$ ansible-playbook provision.yml -t setup_ospf

router1# show ip route ospf
Codes: K - kernel route, C - connected, S - static, R - RIP,
       O - OSPF, I - IS-IS, B - BGP, E - EIGRP, N - NHRP,
       T - Table, v - VNC, V - VNC-Direct, A - Babel, F - PBR,
       f - OpenFabric,
       > - selected route, * - FIB route, q - queued, r - rejected, b - backup
       t - trapped, o - offload failure

O   10.0.10.0/30 [110/1000] is directly connected, enp0s8, weight 1, 00:00:13
O>* 10.0.11.0/30 [110/200] via 10.0.12.2, enp0s9, weight 1, 00:00:08
O   10.0.12.0/30 [110/100] is directly connected, enp0s9, weight 1, 00:00:48
O   192.168.10.0/24 [110/100] is directly connected, enp0s10, weight 1, 00:00:48
O>* 192.168.20.0/24 [110/300] via 10.0.12.2, enp0s9, weight 1, 00:00:08
O>* 192.168.30.0/24 [110/200] via 10.0.12.2, enp0s9, weight 1, 00:00:08

router2# sh ip route ospf
Codes: K - kernel route, C - connected, S - static, R - RIP,
       O - OSPF, I - IS-IS, B - BGP, E - EIGRP, N - NHRP,
       T - Table, v - VNC, V - VNC-Direct, A - Babel, F - PBR,
       f - OpenFabric,
       > - selected route, * - FIB route, q - queued, r - rejected, b - backup
       t - trapped, o - offload failure

O   10.0.10.0/30 [110/1000] is directly connected, enp0s8, weight 1, 00:01:03
O   10.0.11.0/30 [110/100] is directly connected, enp0s9, weight 1, 00:01:03
O>* 10.0.12.0/30 [110/200] via 10.0.11.1, enp0s9, weight 1, 00:00:23
O>* 192.168.10.0/24 [110/300] via 10.0.11.1, enp0s9, weight 1, 00:00:23
O   192.168.20.0/24 [110/100] is directly connected, enp0s10, weight 1, 00:01:03
O>* 192.168.30.0/24 [110/200] via 10.0.11.1, enp0s9, weight 1, 00:00:23
```

После изменения конфигурации на router2 проверю, как маршрутизацию пакетов, запустив также `ping` c `router1`.

```sh
root@router1:~# ping -I 192.168.10.1 192.168.20.1
PING 192.168.20.1 (192.168.20.1) from 192.168.10.1 : 56(84) bytes of data.
64 bytes from 192.168.20.1: icmp_seq=1 ttl=63 time=1.31 ms
64 bytes from 192.168.20.1: icmp_seq=2 ttl=63 time=0.827 ms
```

На router2 запускаем tcpdump, для контроля трафика на порту `enp0s9`.

```sh
root@router2:~# tcpdump -i enp0s9
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on enp0s9, link-type EN10MB (Ethernet), capture size 262144 bytes
20:09:05.603486 IP 192.168.10.1 > router2: ICMP echo request, id 6, seq 6, length 64
20:09:05.603528 IP router2 > 192.168.10.1: ICMP echo reply, id 6, seq 6, length 64
20:09:05.785182 ARP, Request who-has 10.0.11.1 tell router2, length 28
20:09:05.785551 ARP, Reply 10.0.11.1 is-at 08:00:27:4d:f1:f0 (oui Unknown), length 46
20:09:05.787578 ARP, Request who-has router2 tell 10.0.11.1, length 46
20:09:05.787592 ARP, Reply router2 is-at 08:00:27:e4:07:56 (oui Unknown), length 28
20:09:06.605499 IP 192.168.10.1 > router2: ICMP echo request, id 6, seq 7, length 64
20:09:06.605560 IP router2 > 192.168.10.1: ICMP echo reply, id 6, seq 7, length 64
20:09:07.607223 IP 192.168.10.1 > router2: ICMP echo request, id 6, seq 8, length 64
20:09:07.607285 IP router2 > 192.168.10.1: ICMP echo reply, id 6, seq 8, length 64
20:09:08.608896 IP 192.168.10.1 > router2: ICMP echo request, id 6, seq 9, length 64
20:09:08.608968 IP router2 > 192.168.10.1: ICMP echo reply, id 6, seq 9, length 64
20:09:09.609567 IP 192.168.10.1 > router2: ICMP echo request, id 6, seq 10, length 64
20:09:09.609621 IP router2 > 192.168.10.1: ICMP echo reply, id 6, seq 10, length 64
^C
14 packets captured
14 packets received by filter
```

Из данного вывода видно, что теперь пакеты приходят и уходят через один интерфейс `enp0s9`, то есть трафик между `router1` и `router2` ходит через `router3`.


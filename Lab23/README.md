# Мосты, туннели и VPN

#### Домашнее задание: 
1. Между двумя виртуалками поднять vpn в режимах: tun и tap

- описать в чём разница tun и tap
- замерить скорость между виртуальными машинами в туннелях
- сделать вывод об отличающихся показателях скорости

2. Поднять RAS на базе OpenVPN с клиентскими сертификатами, подключиться с локальной  машины на виртуалку.

3. Самостоятельно изучить, поднять ocserv и подключиться с хоста к виртуалке.*

#### Решение:

1. TUN/TAP режимы VPN

Разница между режимами TUN и TAP в том, что они работают на разных уровнях модели OSI.  
`TAP` эмулирует Ethernet устройство и работает на `канальном уровне` модели OSI, оперируя кадрами Ethernet.  
`TUN` (сетевой туннель) работает на `сетевом уровне` модели OSI, оперируя IP пакетами.
TAP используется для создания сетевого моста, тогда как TUN для маршрутизации. 

Если необходимо растянуть один сегмент L2 с одной адресацией (vlan - широковещательный домен), то это - `TAP`.  
Если например объединить две сети с разной адресацией - то это `TUN`.


Выполним замер скорости в разных режимах работы туннеля. 
- Тестируем TAP. На сервере запускаем iperf3 в режиме сервер, а на клиенте в режиме клиент с указанием ip сервера, продолжительности проверки в секундах `-t` интервалом вывода информации на экран `-i`.

```sh
[root@server ~]# ip a | grep tap0
12: tap0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UNKNOWN group default qlen 100
    inet 10.10.10.1/24 brd 10.10.10.255 scope global tap0

[root@server ~]# iperf3 -s &
[1] 7484
[root@server ~]# 
-----------------------------------------------------------
Server listening on 5201
-----------------------------------------------------------
Accepted connection from 10.10.10.2, port 32948
[  5] local 10.10.10.1 port 5201 connected to 10.10.10.2 port 32950
[ ID] Interval           Transfer     Bandwidth
[  5]   0.00-1.00   sec  14.9 MBytes   125 Mbits/sec
[  5]   1.00-2.00   sec  15.0 MBytes   126 Mbits/sec
[  5]   2.00-3.00   sec  15.3 MBytes   128 Mbits/sec
[  5]   3.00-4.00   sec  14.9 MBytes   125 Mbits/sec
[  5]   4.00-5.00   sec  15.3 MBytes   129 Mbits/sec
[  5]   5.00-6.00   sec  15.3 MBytes   128 Mbits/sec
[  5]   6.00-7.00   sec  15.7 MBytes   132 Mbits/sec
[  5]   7.00-8.00   sec  15.2 MBytes   128 Mbits/sec
[  5]   8.00-9.00   sec  15.0 MBytes   126 Mbits/sec
[  5]   9.00-10.00  sec  15.6 MBytes   131 Mbits/sec
[  5]  10.00-11.00  sec  15.4 MBytes   129 Mbits/sec
[  5]  11.00-12.00  sec  15.1 MBytes   127 Mbits/sec
[  5]  12.00-13.00  sec  15.4 MBytes   129 Mbits/sec
[  5]  13.00-14.00  sec  15.8 MBytes   132 Mbits/sec
[  5]  14.00-15.00  sec  15.6 MBytes   131 Mbits/sec
[  5]  15.00-16.00  sec  15.3 MBytes   128 Mbits/sec
[  5]  16.00-17.00  sec  15.3 MBytes   129 Mbits/sec
[  5]  17.00-18.00  sec  15.7 MBytes   131 Mbits/sec
[  5]  18.00-19.00  sec  15.5 MBytes   130 Mbits/sec
[  5]  19.00-20.00  sec  15.0 MBytes   126 Mbits/sec
[  5]  20.00-21.00  sec  15.6 MBytes   131 Mbits/sec
[  5]  21.00-22.00  sec  14.9 MBytes   125 Mbits/sec
[  5]  22.00-23.00  sec  16.0 MBytes   134 Mbits/sec
[  5]  23.00-24.01  sec  15.2 MBytes   127 Mbits/sec
[  5]  24.01-25.00  sec  15.8 MBytes   133 Mbits/sec
[  5]  25.00-26.00  sec  15.4 MBytes   130 Mbits/sec
[  5]  26.00-27.00  sec  15.5 MBytes   130 Mbits/sec
[  5]  27.00-28.00  sec  15.7 MBytes   131 Mbits/sec
[  5]  28.00-29.00  sec  15.7 MBytes   132 Mbits/sec
[  5]  29.00-30.00  sec  15.8 MBytes   133 Mbits/sec
[  5]  30.00-31.00  sec  14.7 MBytes   123 Mbits/sec
[  5]  31.00-32.00  sec  15.5 MBytes   130 Mbits/sec
[  5]  32.00-33.00  sec  15.4 MBytes   129 Mbits/sec
[  5]  33.00-34.00  sec  15.5 MBytes   130 Mbits/sec
[  5]  34.00-35.00  sec  15.3 MBytes   128 Mbits/sec
[  5]  35.00-36.00  sec  14.8 MBytes   124 Mbits/sec
[  5]  36.00-37.00  sec  15.6 MBytes   131 Mbits/sec
[  5]  37.00-38.00  sec  15.2 MBytes   127 Mbits/sec
[  5]  38.00-39.00  sec  15.5 MBytes   130 Mbits/sec
[  5]  39.00-40.00  sec  14.9 MBytes   126 Mbits/sec
[  5]  40.00-40.07  sec  1.01 MBytes   126 Mbits/sec
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bandwidth
[  5]   0.00-40.07  sec  0.00 Bytes  0.00 bits/sec                  sender
[  5]   0.00-40.07  sec   615 MBytes   129 Mbits/sec                  receiver
-----------------------------------------------------------
Server listening on 5201
-----------------------------------------------------------

[root@client ~]# iperf3 -c 10.10.10.1 -t 40 -i 5
Connecting to host 10.10.10.1, port 5201
[  4] local 10.10.10.2 port 32950 connected to 10.10.10.1 port 5201
[ ID] Interval           Transfer     Bandwidth       Retr  Cwnd
[  4]   0.00-5.00   sec  77.5 MBytes   130 Mbits/sec  223    188 KBytes
[  4]   5.00-10.00  sec  76.9 MBytes   129 Mbits/sec   55    257 KBytes
[  4]  10.00-15.00  sec  77.4 MBytes   130 Mbits/sec   52    334 KBytes
[  4]  15.00-20.00  sec  76.8 MBytes   129 Mbits/sec    8    350 KBytes
[  4]  20.00-25.00  sec  77.4 MBytes   130 Mbits/sec   52    295 KBytes
[  4]  25.00-30.00  sec  77.8 MBytes   131 Mbits/sec   15    378 KBytes
[  4]  30.00-35.00  sec  76.8 MBytes   129 Mbits/sec   20    369 KBytes
[  4]  35.00-40.00  sec  76.1 MBytes   128 Mbits/sec    7    344 KBytes
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bandwidth       Retr
[  4]   0.00-40.00  sec   617 MBytes   129 Mbits/sec  432             sender
[  4]   0.00-40.00  sec   615 MBytes   129 Mbits/sec                  receiver

iperf Done.
```

- Тестируем TUN. Для этого нам необходимо в файле main.yml изменить значение переменной vpn_mode с tap на tun и заново запустить playbook. После этого провести аналогичные измерения скорости.

```sh
[root@server ~]# ip a | grep tun0
13: tun0: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UNKNOWN group default qlen 100
    inet 10.10.10.1/24 brd 10.10.10.255 scope global tun0

[root@server ~]# iperf3 -s &
[2] 10422
[root@server ~]# iperf3: error - unable to start listener for connections: Address already in use
iperf3: exiting
Accepted connection from 10.10.10.2, port 32952
[  5] local 10.10.10.1 port 5201 connected to 10.10.10.2 port 32954
[ ID] Interval           Transfer     Bandwidth
[  5]   0.00-1.00   sec  13.3 MBytes   112 Mbits/sec
[  5]   1.00-2.00   sec  14.1 MBytes   119 Mbits/sec
[  5]   2.00-3.00   sec  13.9 MBytes   117 Mbits/sec
[  5]   3.00-4.00   sec  14.0 MBytes   118 Mbits/sec
[  5]   4.00-5.00   sec  14.5 MBytes   121 Mbits/sec
[  5]   5.00-6.00   sec  15.8 MBytes   133 Mbits/sec
[  5]   6.00-7.00   sec  15.4 MBytes   129 Mbits/sec
[  5]   7.00-8.00   sec  15.8 MBytes   133 Mbits/sec
[  5]   8.00-9.00   sec  15.4 MBytes   129 Mbits/sec
[  5]   9.00-10.00  sec  15.4 MBytes   129 Mbits/sec
[  5]  10.00-11.00  sec  15.4 MBytes   129 Mbits/sec
[  5]  11.00-12.00  sec  15.4 MBytes   129 Mbits/sec
[  5]  12.00-13.00  sec  15.3 MBytes   129 Mbits/sec
[  5]  13.00-14.00  sec  15.7 MBytes   132 Mbits/sec
[  5]  14.00-15.00  sec  15.5 MBytes   130 Mbits/sec
[  5]  15.00-16.00  sec  15.3 MBytes   128 Mbits/sec
[  5]  16.00-17.00  sec  15.4 MBytes   129 Mbits/sec
[  5]  17.00-18.00  sec  15.5 MBytes   130 Mbits/sec
[  5]  18.00-19.00  sec  15.5 MBytes   130 Mbits/sec
[  5]  19.00-20.00  sec  15.8 MBytes   133 Mbits/sec
[  5]  20.00-21.00  sec  15.7 MBytes   132 Mbits/sec
[  5]  21.00-22.00  sec  14.3 MBytes   120 Mbits/sec
[  5]  22.00-23.01  sec  15.8 MBytes   132 Mbits/sec
[  5]  23.01-24.00  sec  15.4 MBytes   130 Mbits/sec
[  5]  24.00-25.00  sec  15.7 MBytes   131 Mbits/sec
[  5]  25.00-26.00  sec  14.3 MBytes   120 Mbits/sec
[  5]  26.00-27.00  sec  15.4 MBytes   129 Mbits/sec
[  5]  27.00-28.00  sec  14.2 MBytes   119 Mbits/sec
[  5]  28.00-29.01  sec  14.3 MBytes   120 Mbits/sec
[  5]  29.01-30.00  sec  15.5 MBytes   131 Mbits/sec
[  5]  30.00-31.00  sec  15.3 MBytes   129 Mbits/sec
[  5]  31.00-32.00  sec  14.0 MBytes   118 Mbits/sec
[  5]  32.00-33.00  sec  14.5 MBytes   121 Mbits/sec
[  5]  33.00-34.00  sec  14.0 MBytes   117 Mbits/sec
[  5]  34.00-35.00  sec  15.3 MBytes   128 Mbits/sec
[  5]  35.00-36.00  sec  15.4 MBytes   129 Mbits/sec
[  5]  36.00-37.00  sec  15.4 MBytes   129 Mbits/sec
[  5]  37.00-38.00  sec  15.2 MBytes   128 Mbits/sec
[  5]  38.00-39.00  sec  15.6 MBytes   131 Mbits/sec
[  5]  39.00-40.00  sec  15.2 MBytes   128 Mbits/sec
[  5]  40.00-40.05  sec   778 KBytes   128 Mbits/sec
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bandwidth
[  5]   0.00-40.05  sec  0.00 Bytes  0.00 bits/sec                  sender
[  5]   0.00-40.05  sec   604 MBytes   126 Mbits/sec                  receiver
-----------------------------------------------------------
Server listening on 5201
-----------------------------------------------------------
[2]+  Exit 1                  iperf3 -s

[root@client ~]# iperf3 -c 10.10.10.1 -t 40 -i 5
Connecting to host 10.10.10.1, port 5201
[  4] local 10.10.10.2 port 32954 connected to 10.10.10.1 port 5201
[ ID] Interval           Transfer     Bandwidth       Retr  Cwnd
[  4]   0.00-5.01   sec  71.4 MBytes   120 Mbits/sec   80    240 KBytes
[  4]   5.01-10.00  sec  77.9 MBytes   131 Mbits/sec   75    322 KBytes
[  4]  10.00-15.00  sec  77.4 MBytes   130 Mbits/sec  182    267 KBytes
[  4]  15.00-20.00  sec  77.5 MBytes   130 Mbits/sec  103    201 KBytes
[  4]  20.00-25.00  sec  77.0 MBytes   129 Mbits/sec   52    223 KBytes
[  4]  25.00-30.00  sec  73.5 MBytes   123 Mbits/sec   56    210 KBytes
[  4]  30.00-35.00  sec  73.4 MBytes   123 Mbits/sec   93    174 KBytes
[  4]  35.00-40.00  sec  76.5 MBytes   128 Mbits/sec   12    317 KBytes
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bandwidth       Retr
[  4]   0.00-40.00  sec   605 MBytes   127 Mbits/sec  653             sender
[  4]   0.00-40.00  sec   604 MBytes   127 Mbits/sec                  receiver
iperf Done.
```

После замеров видно:
 - в режиме TAP что за 40 секунд прокачалось 615 MBytes со средней скоростью 129 Mbits/sec 
 - в режиме TUN прокачалось 604 MBytes со средней скоростью 127 Mbits/sec. 
 
 Исходя из получившихся замеров - разница в производительности туннеля в данных условиях минимальна, но TAP чуть более производительней.

 2. RAS на базе OpenVPN

 Для тестирования был создан отдельный Vagrantfile с описание сторонных vm. Были взяты два виртуальных сервера: server и clientс с добавленными к ним по одному интерфейсу с локальными сетями: 172.16.10.0/24 и 172.16.20.0/24. Это необходимо для тестирования того, что за серверами есть ещё сети и между ними будет ходить маршрутизация.  
 Для этого добавлем в конфиг серверов:

```sh
route 172.16.20.0 255.255.255.0
push "route 172.16.10.0 255.255.255.0"
```
И дополнительно создаём файл /etc/openvpn/client/client со следующим содержимым:
```sh
iroute 172.16.20.0 255.255.255.0
```

Server vm:
```sh
administrator@lablotus01:~/otus_vm/Lab23/openvpn$ vagrant ssh server
Last login: Thu Jun 23 18:11:34 2022 from 192.168.56.1
[vagrant@server ~]$ sudo -i
[root@server ~]# ip route
default via 10.0.2.2 dev eth0 proto dhcp metric 101
10.0.2.0/24 dev eth0 proto kernel scope link src 10.0.2.15 metric 101
10.10.10.0/24 via 10.10.10.2 dev tun0
10.10.10.2 dev tun0 proto kernel scope link src 10.10.10.1
172.16.10.0/24 dev eth3 proto kernel scope link src 172.16.10.1 metric 103
172.16.20.0/24 via 10.10.10.2 dev tun0
192.168.10.0/24 dev eth1 proto kernel scope link src 192.168.10.10 metric 100
192.168.56.0/24 dev eth2 proto kernel scope link src 192.168.56.10 metric 102
[root@server ~]# ping -c 4 172.16.20.1
PING 172.16.20.1 (172.16.20.1) 56(84) bytes of data.
64 bytes from 172.16.20.1: icmp_seq=1 ttl=64 time=1.07 ms
64 bytes from 172.16.20.1: icmp_seq=2 ttl=64 time=0.650 ms
64 bytes from 172.16.20.1: icmp_seq=3 ttl=64 time=1.07 ms
64 bytes from 172.16.20.1: icmp_seq=4 ttl=64 time=1.06 ms

--- 172.16.20.1 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3002ms
rtt min/avg/max/mdev = 0.650/0.966/1.075/0.186 ms
```

Client vm:
```sh
administrator@lablotus01:~/otus_vm/Lab23/openvpn$ vagrant ssh client
Last login: Thu Jun 23 18:11:34 2022 from 192.168.56.1
[vagrant@client ~]$ sudo -i
[root@client ~]# ip route
default via 10.0.2.2 dev eth0 proto dhcp metric 103
10.0.2.0/24 dev eth0 proto kernel scope link src 10.0.2.15 metric 103
10.10.10.0/24 via 10.10.10.5 dev tun0
10.10.10.5 dev tun0 proto kernel scope link src 10.10.10.6
172.16.10.0/24 via 10.10.10.5 dev tun0
172.16.20.0/24 dev eth3 proto kernel scope link src 172.16.20.1 metric 102
192.168.10.0/24 dev eth1 proto kernel scope link src 192.168.10.20 metric 100
192.168.56.0/24 dev eth2 proto kernel scope link src 192.168.56.20 metric 101
[root@client ~]# ping -c 4 172.16.10.1
PING 172.16.10.1 (172.16.10.1) 56(84) bytes of data.
64 bytes from 172.16.10.1: icmp_seq=1 ttl=64 time=1.14 ms
64 bytes from 172.16.10.1: icmp_seq=2 ttl=64 time=1.04 ms
64 bytes from 172.16.10.1: icmp_seq=3 ttl=64 time=1.10 ms
64 bytes from 172.16.10.1: icmp_seq=4 ttl=64 time=1.10 ms

--- 172.16.10.1 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3004ms
rtt min/avg/max/mdev = 1.047/1.100/1.145/0.053 ms
```

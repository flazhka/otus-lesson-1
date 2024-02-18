#  Репликация  BD MySQL

#### Домашнее задание: 
В материалах приложены ссылки на vagrant для репликации и дамп базы bet.dmp.
Базу развернуть на мастере и настроить так, чтобы реплицировались таблицы:
| bookmaker |
| competition |
| market |
| odds |
| outcom|

Настроить GTID репликацию

#### Решение:  

Лабораторный стенд для настройки основного сервера и сервера репликации СУБД MySQL под управлением системы администрирования Percona.

После запуска vagarnt будут созданы два виртуальных сервера mysqlmaster и mysqlslave, с установленными Percona-Server и настроенной реплицацией между ними. Настройки произведены согласно методички и использования ansible модулей для работы с MySQL - community.mysql.mysql_xxxxx.

Для проверки: 
Выполним подключение к mysqlmaster ноде и проверим работоспособность.

```sh
administrator@lablotus01:~/otus_vm/Lab28$ vagrant ssh mysqlmaster
Last login: Sun Feb 18 23:25:03 2024 from 10.0.2.2
[vagrant@mysqlmaster ~]$ sudo su
[root@mysqlmaster vagrant]# mysql
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 10
Server version: 5.7.44-48-log Percona Server (GPL), Release 48, Revision 497f936a373

Copyright (c) 2009-2023 Percona LLC and/or its affiliates
Copyright (c) 2000, 2023, Oracle and/or its affiliates.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.
Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> USE bet;
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed

mysql> INSERT INTO bookmaker (id,bookmaker_name) VALUES(1,'Otus');
Query OK, 1 row affected (0.01 sec)

mysql> SELECT * FROM bookmaker;
+----+----------------+
| id | bookmaker_name |
+----+----------------+
|  4 | betway         |
|  5 | bwin           |
|  6 | ladbrokes      |
|  1 | Otus           |
|  3 | unibet         |
+----+----------------+
5 rows in set (0.00 sec)
```

Выполним подключение к mysqlslave ноде и проверим работоспособность репликации.

```sh
administrator@lablotus01:~/otus_vm/Lab28$ vagrant ssh mysqlslave
Last login: Sun Feb 18 23:28:36 2024 from 10.0.2.2
[vagrant@mysqlslave ~]$ sudo su
[root@mysqlslave vagrant]# mysql -e "SHOW SLAVE STATUS\G" | grep Slave
               Slave_IO_State: Waiting for master to send event
             Slave_IO_Running: Yes
            Slave_SQL_Running: Yes
      Slave_SQL_Running_State: Slave has read all relay log; waiting for more updates

[root@mysqlslave vagrant]# mysql -e "use bet; SELECT * FROM bookmaker;"
+----+----------------+
| id | bookmaker_name |
+----+----------------+
|  4 | betway         |
|  5 | bwin           |
|  6 | ladbrokes      |
|  1 | Otus           |
|  3 | unibet         |
+----+----------------+
[root@mysqlslave vagrant]# 
```

Vagrant на разных версия установки не различает установленную версию ansible:
agrant gathered an unknown Ansible version:
and falls back on the compatibility mode '1.8'.

После чего были проблемы с коммандлетами используемыми в модулях.
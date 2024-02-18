#  Репликация  BD MySQL

#### Домашнее задание: 

Научиться настраивать репликацию и создавать резервные копии в СУБД PostgreSQL

1) Настроить hot_standby репликацию с использованием слотов
2) Настроить правильное резервное копирование


#### Решение:  

После запуска vagarnt будут созданы два виртуальных сервера, с установленными PostgreSQL 14.5 и настроенной потоковой асинхронной репликацией в режиме Master-Replica. В playbook создаётся тестовая база с тестовой табличкой на master сервере. Проверим её наличие на slave, а также создадим ещё одну и проверим рпликацию.

Для проверки: 
Выполним подключение к pgsqlmaster и проверим состояние базы.

```sh
administrator@lablotus01:~/otus_vm/Lab29$ vagrant ssh pgsqlmaster
Last login: Sun Feb 18 13:43:01 2024 from 10.0.2.2

vagrant@pgsqlmaster:~$ sudo su
root@pgsqlmaster:/home/vagrant# su - postgres
postgres@pgsqlmaster:~$ psql -c "SELECT * FROM pg_replication_slots;"
postgres@pgsqlmaster:~$ psql -c "SELECT * FROM pg_replication_slots;"

slot_name | plugin | slot_type | datoid | database | temporary | active | active_pid | xmin | catalog_xmin | restart_lsn | confirmed_flush_lsn | wal_status | safe_wal_size | two_phase 
----------+--------+-----------+--------+----------+-----------+--------+------------+------+--------------+-------------+---------------------+------------+---------------+-----------
pgstandby1|        | physical  |        |          | f         | t      |       9691 |      |              | 0/3000148   |                     | reserved   |               | f
(1 row)

postgres@pgsqlmaster:~$ psql
psql (14.11 (Ubuntu 14.11-1.pgdg20.04+1))
Type "help" for help.

postgres=# \c test_base 
You are now connected to database "test_base" as user "postgres".

test_base=# \dt
         List of relations
 Schema |  Name  | Type  |  Owner   
--------+--------+-------+----------
 public | table1 | table | postgres
(1 row)

test_base=# 

```

Выполним подключение к pgsqlslave и проверим состояние базы.
```sh
administrator@lablotus01:~/otus_vm/Lab29$ vagrant ssh pgsqlslave
Last login: Sun Feb 18 13:38:35 2024 from 10.0.2.2

vagrant@pgsqlslave:~$ sudo su
root@pgsqlslave:/home/vagrant# su - postgres
postgres@pgsqlslave:~$ psql
psql (14.11 (Ubuntu 14.11-1.pgdg20.04+1))
Type "help" for help.

postgres=# \l
                              List of databases
   Name    |  Owner   | Encoding | Collate |  Ctype  |   Access privileges   
-----------+----------+----------+---------+---------+-----------------------
 postgres  | postgres | UTF8     | C.UTF-8 | C.UTF-8 | 
 template0 | postgres | UTF8     | C.UTF-8 | C.UTF-8 | =c/postgres          +
           |          |          |         |         | postgres=CTc/postgres
 template1 | postgres | UTF8     | C.UTF-8 | C.UTF-8 | =c/postgres          +
           |          |          |         |         | postgres=CTc/postgres
 test_base | postgres | UTF8     | C.UTF-8 | C.UTF-8 | 
(4 rows)

postgres=# \c test_base 
You are now connected to database "test_base" as user "postgres".

test_base=# \dt
         List of relations
 Schema |  Name  | Type  |  Owner   
--------+--------+-------+----------
 public | table1 | table | postgres
(1 row)

test_base=# 
```

Проверим репликацию:

```sh 
postgres@pgsqlmaster:~$ psql
psql (14.11 (Ubuntu 14.11-1.pgdg20.04+1))
Type "help" for help.

postgres=# \c test_base 
You are now connected to database "test_base" as user "postgres".
test_base=# \dt
         List of relations
 Schema |  Name  | Type  |  Owner   
--------+--------+-------+----------
 public | table1 | table | postgres
(1 row)

test_base=# CREATE TABLE TEST (id INT, name TEXT);
CREATE TABLE
test_base=# \dt
         List of relations
 Schema |  Name  | Type  |  Owner   
--------+--------+-------+----------
 public | table1 | table | postgres
 public | test   | table | postgres
(2 rows)

test_base=# INSERT INTO test (id, name) VALUES (10, 1111);
INSERT 0 1

test_base=# select * from test;
 id | name 
----+------
 10 | 1111
(1 row)

test_base=# 
```

```sh
postgres@pgsqlslave:~$ psql
psql (14.11 (Ubuntu 14.11-1.pgdg20.04+1))
Type "help" for help.
postgres=# \c test_base 
You are now connected to database "test_base" as user "postgres".

test_base=# \dt
         List of relations
 Schema |  Name  | Type  |  Owner   
--------+--------+-------+----------
 public | table1 | table | postgres
(1 row)

    AFTER CREATING NEW TABLE test!!!

test_base=# \dt
         List of relations
 Schema |  Name  | Type  |  Owner   
--------+--------+-------+----------
 public | table1 | table | postgres
 public | test   | table | postgres
(2 rows)

test_base=# select * from test;
 id | name 
----+------
 10 | 1111
(1 row)

test_base=# 
```

А также на slave можно посмотреть статус потоковой передачи командой `SELECT * FROM pg_stat_wal_receiver;`
![repl](https://github.com/flazhka/otuslab-homework/Lab29/1.png)


- В качестве бэкапа базы была выбрана встроенная утилита - pg_dump. Добавлен скрипт, который бэкапит базу `test_base` и чистит бэкапы старше 7 дней. 

Скрипт добавлен в крон - для выполнения бэкапа каждую минуту.  
Выполняется на slave сервере. 

Для проверки, удалим на мастере из базы `test_base` ранее созданные таблицы, далее скачаем бэкап и восстановим его на мастере, и проверим, как данные снова реплицируются на slave.

```sh
test_base=# \dt
         List of relations
 Schema |  Name  | Type  |  Owner   
--------+--------+-------+----------
 public | table1 | table | postgres
 public | test   | table | postgres
(2 rows)

test_base=# DROP TABLE test;
DROP TABLE
test_base=# DROP TABLE table1;
DROP TABLE
test_base=# \dt
Did not find any relations.
test_base=# 
```


Востановление из бэкапа:
```sh
vagrant@pgsqlmaster:~$ sudo su
root@pgsqlmaster:/home/vagrant# su - postgres
postgres@pgsqlmaster:~$ scp -r postgres@192.168.56.31:/var/lib/postgresql/backup/pgsql_15:10:02-18-02-2024.gz ~/pgsql_15:10:02-18-02-2024.gz
Warning: Permanently added '192.168.56.31' (ECDSA) to the list of known hosts.
pgsql_15:10:02-18-02-2024.gz                                      100% 1715   519.1KB/s   00:00    
                          
postgres@pgsqlmaster:~$ pg_restore -d test_base -j 8 ~/pgsql_15\:10\:02-18-02-2024.gz
postgres@pgsqlmaster:~$ psql
psql (14.11 (Ubuntu 14.11-1.pgdg20.04+1))
Type "help" for help.

postgres=# \c test_base 
You are now connected to database "test_base" as user "postgres".
test_base=# \dt
         List of relations
 Schema |  Name  | Type  |  Owner   
--------+--------+-------+----------
 public | table1 | table | postgres
 public | test   | table | postgres
(2 rows)

test_base=# select * from test;
 id | name 
----+------
 10 | 1111
(1 row)

test_base=# 
```
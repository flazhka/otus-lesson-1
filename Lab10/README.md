# Bash

#### Домашнее задание:
Написать скрипт на BASH для CRON, который раз в час будет формировать письмо и отправлять на заданную почту. Необходимая информация в письме:
- Список IP адресов (с наибольшим кол-вом запросов) с указанием кол-ва запросов c момента последнего запуска скрипта;
- Список запрашиваемых URL (с наибольшим кол-вом запросов) с указанием кол-ва запросов c момента последнего запуска скрипта;
- Ошибки веб-сервера/приложения c момента последнего запуска;
- Список всех кодов HTTP ответа с указанием их кол-ва с момента последнего запуска скрипта.
- Скрипт должен предотвращать одновременный запуск нескольких копий, до его завершения.
- В письме должен быть прописан обрабатываемый временной диапазон.


#### Cron
Задание для  Cron:

```
@hourly /home/administrator/otus_vm/Lab10/mail_sender_cron.sh flazhka@gmail.com
```

#### Парсер

```sh
#!/bin/bash
# Путь к файлу access.log
file_log="/home/administrator/otus_vm/Lab10/access-4560-644067.log"

# Почтовый адрес получателей
email=$1

# Проверка наличия файла блокировки
if [ -f /tmp/script.lock ]; then
  echo "Script is already running. Please exit."
  exit 1
fi

# Создание файла блокировки
touch /home/administrator/otus_vm/Lab10/script.lock

# Временная метка последнего запуска скрипта
last_run=$(cat /home/administrator/otus_vm/Lab10/last_run_timestamp 2>/dev/null)
current_time=$(date +%s)
echo "$current_time" > /home/administrator/otus_vm/Lab10/last_run_timestamp

# Формирование письма
report="Отчёт за период с $(date -d @$last_run) до $(date)"

# Список IP адресов с наибольшим количеством запросов
TOP_IPs=$(awk -v last_run="$last_run" '$4 > last_run {print $1}' "$file_log" | sort | uniq -c | sort -nr | head)
report+="\n\nСписок IP адресов с наибольшим количеством запросов:\n$TOP_IPs"

# Список URL с наибольшим количеством запросов
TOP_URLs=$(awk -v last_run="$last_run" '$4 > last_run {print $7}' "$file_log" | sort | uniq -c | sort -nr | head)
report+="\n\nСписок URL с наибольшим количеством запросов:\n$TOP_URLs"

# Ошибки сервера/приложения
ERRORS=$(awk -v last_run="$last_run" '$4 > last_run && $9 >= 400 {print $9}' "$file_log" | sort | uniq -c)
report+="\n\nОшибки сервера/приложения:\n$ERRORS"

# Список всех кодов HTTP ответа
HTTP_CODES=$(awk -v last_run="$last_run" '$4 > last_run {print $9}' "$file_log" | sort | uniq -c)
report+="\n\nСписок всех кодов HTTP ответа:\n$HTTP_CODES"

# Отправка письма
#echo -e "$report" > report.txt
```

Также был подготовлен Vagrantfile для быстрого развертывания парсера.

По итогу работы парсера получаем отчет который может быть отправлен по почте или выведен в файл, содержащий:

```
Отчёт об активности сервера за период с Чт 19 окт 2023 00:09:00 MSK до Чт 19 окт 2023 00:10:00 MSK

Список IP адресов с наибольшим количеством запросов:
     45 93.158.167.130
     39 109.236.252.130
     37 212.57.117.19
     33 188.43.241.106
     31 87.250.233.68
     24 62.75.198.172
     22 148.251.223.21
     20 185.6.8.9
     17 217.118.66.161
     16 95.165.18.146

Список URL с наибольшим количеством запросов:
    157 /
    120 /wp-login.php
     57 /xmlrpc.php
     26 /robots.txt
     12 /favicon.ico
     11 400
      9 /wp-includes/js/wp-embed.min.js?ver=5.0.4
      7 /wp-admin/admin-post.php?page=301bulkoptions
      7 /1
      6 /wp-content/uploads/2016/10/robo5.jpg

Ошибки сервера/приложения:
      7 400
      1 403
     51 404
      1 405
      2 499
      3 500

Список всех кодов HTTP ответа:
     11 "-"
    498 200
     95 301
      1 304
      7 400
      1 403
     51 404
      1 405
      2 499
      3 500
```


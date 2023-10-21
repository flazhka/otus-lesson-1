#!/bin/bash

# Путь к файлу access.log
file_log="/home/administrator/otus_vm/Lab10/access-4560-644067.log"

# Почтовый адрес получателя
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

report_send()
{
(
cat - <<END
	Subject: Otus web server report
	From: test@localhost
	To: $email
${report[@]}
END
) | /usr/sbin/sendmail $email
echo "Report was sent at $(date)"
}

report_send
rm /home/administrator/otus_vm/Lab10/script.lock

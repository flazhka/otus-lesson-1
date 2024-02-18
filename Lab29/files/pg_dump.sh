#!/usr/bin/sh

PATH=/etc:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

database=test_base
back_path=/var/lib/postgresql/backup


find $back_path \( -name "*-1[^5].*" -o -name "*-[023]?.*" \) -ctime +7 -delete
pg_dump -Fc $database > $back_path/pgsql_$(date "+%T-%d-%m-%Y").gz
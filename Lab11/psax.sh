#!/usr/bin/env bash
set -eux

# Kоличество тактов в секунду
clk_tck=`getconf CLK_TCK`

# В цикле для каждого процесса PID забираем информацию из 
(
echo "PID|TTY|STAT|TIME|COMMAND";
for pid in `ls /proc | grep -E "^[0-9]+$"`; do
    if [ -d /proc/$pid ]; then
        stat=`</proc/$pid/stat`
        # Получаем состояние процесса
        cmd=`echo "$stat" | awk -F" " '{print $2}'`
        state=`echo "$stat" | awk -F" " '{print $3}'`
        tty=`echo "$stat" | awk -F" " '{print $7}'`

        # Получаем время выполнения процесса 
        utime=`echo "$stat" | awk -F" " '{print $14}'`
        stime=`echo "$stat" | awk -F" " '{print $15}'`
        # Cначала определяем общее время, затраченное на процесс
        ttime=$((utime + stime))
        # Далее мы получаем общее время, прошедшее в секундах с момента запуска процесса
        time=$((ttime / clk_tck))

        echo "${pid}|${tty}|${state}|${time}|${cmd}"
    fi
done
) | column -t -s "|"
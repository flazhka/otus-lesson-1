# Пользователи и группы Авторизация и аутентификация

#### Домашнее задание:
    1. Запретить всем пользователям, кроме группы admin, логин в выходные (суббота и воскресенье), без учета праздников
    2. Дать конкретному пользователю права работать с докером и возможность рестартить докер сервис
#### Запретить логин в выходные (суббота и воскресенье) дни
1. Подключился к vm `vagrant ssh`
2. Создал пользователей `otusadm` и `otus`:  
```
useradd otusadm  
useradd otus
```
3. Создал пользователям пароли:  
```
echo "Otus2022!" | sudo passwd --stdin otusadm  
echo "Otus2022!" | sudo passwd --stdin otus
```
4. Создал группу admin:  
```
groupadd -f admin
```
5. Добавляем пользователей `vagrant, root, otusadm` в группу `admin`:  
```
usermod otusadm -a -G admin  
usermod root -a -G admin  
usermod vagrant -a -G admin
```
6. Тестирование подключения
```sh
administrator@lablotus01:~/otus_vm/Lab16$ ssh otus@192.168.56.20
The authenticity of host '192.168.56.20 (192.168.56.20)' can't be established.
ED25519 key fingerprint is SHA256:39eTd4Ld3QEPGEDs8e3stwMV9EwfM/M0FYCZky/bSwo.
This key is not known by any other names
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '192.168.56.20' (ED25519) to the list of known hosts.
otus@192.168.56.20's password: 
[otus@pam ~]$ exit
logout
Connection to 192.168.56.20 closed.
administrator@lablotus01:~/otus_vm/Lab16$ ssh otusadm@192.168.56.20
otusadm@192.168.56.20's password: 
[otusadm@pam ~]$ exit
logout
Connection to 192.168.56.20 closed.
```
    Далее настроил правило, по которому все пользователи кроме тех, что указаны в группе admin не смогут подключаться в выходные дни:
7. Проверил, что пользователи root, vagrant и otusadm есть в группе admin:
```sh
[root@pam vagrant]# cat /etc/group | grep admin
admin:x:1003:otusadm,root,vagrant
```
8. Создадим файл-скрипт и добавим права на исполнение файла /usr/local/bin/login.sh
`vim /usr/local/bin/login.sh`  
`chmod +x /usr/local/bin/login.sh`
```sh
#!/bin/bash
#Первое условие: если день недели суббота или воскресенье
if [ $(date +%a) = "Sat" ] || [ $(date +%a) = "Sun" ]; then
 #Второе условие: входит ли пользователь в группу admin
 if getent group admin | grep -qw "$PAM_USER"; then
        #Если пользователь входит в группу admin, то он может подключиться
        exit 0
      else
        #Иначе ошибка (не сможет подключиться)
        exit 1
    fi
  #Если день не выходной, то подключиться может любой пользователь
  else
    exit 0
fi
```
9. Укажем в файле /etc/pam.d/sshd модуль pam_exec и наш скрипт:  
`vi /etc/pam.d/sshd` 
```sh
#%PAM-1.0
auth       substack     password-auth
auth       include      postlogin
account    required     pam_exec.so /usr/local/bin/login.sh
account    required     pam_sepermit.so
...
```
10. Выполним проверку и установим дату на выходной день:
date -s "2023-11-11 10:10:00"
```sh
[root@pam vagrant]# date -s "2023-11-11 10:10:00"
Sat Nov 11 10:10:00 AM UTC 2023
```
11. Проверяем что пользователь otusadm подключается без проблем, в у пользователя otus возникает ошибка:
```sh
administrator@lablotus01:~/otus_vm/Lab16$ ssh otus@192.168.56.20
otus@192.168.56.20's password: 
/usr/local/bin/login.sh failed: exit code 1
Connection closed by 192.168.56.20 port 22
```
```sh
administrator@lablotus01:~/otus_vm/Lab16$ ssh otusadm@192.168.56.20
otusadm@192.168.56.20's password: 
Last login: Wed Nov 15 06:13:42 2023 from 192.168.56.1
[otusadm@pam ~]$ whoami
otusadm
[otusadm@pam ~]$ exit
logout
Connection to 192.168.56.20 closed.
```
Как видно, залогиниться в субботу можно только пользователю из группы admin.

#### Дать пользователю права на докер
В данном случае считаю, что Docker уже установлен на сервере.
1. Создаём пользователя, задаём пароль. Группа docker уже создана в процессе установки docker.
```
useradd otusadm
echo "Otus2023!" | sudo passwd --stdin otusadm
```
2. Пользователя otusadm добавляем в группу docker и дадим ему права для возможности рестарта сервиса путём редактирования /etc/sudoers через visudo.
```
usermod -aG docker otusadm
sudo visudo
```
3. В  файл добавить строку
```
%otusadm ALL=NOPASSWD: /bin/systemctl restart docker.service
```
4. Затем выполнить
```
chmod 0440 /etc/sudoers.d/vagrant
```
5. Выполним перезапуск сервиса docker 
```
systemctl restart docker
```
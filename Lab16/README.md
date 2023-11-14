# Пользователи и группы Авторизация и аутентификация
 
#### Домашнее задание:
    Запретить всем пользователям, кроме группы admin, логин в выходные (суббота и воскресенье), без учета праздников
    
    Дать конкретному пользователю права работать с докером и возможность рестартить докер сервис


#### 

1. Подключился к vm `vagrant ssh`

2. Создал пользователей `otusadm` и `otus`:  
```
sudo useradd otusadm  
sudo useradd otus
```
3. Создал пользователям пароли:  
```
echo "Otus2022!" | sudo passwd --stdin otusadm  
echo "Otus2022!" | sudo passwd --stdin otus
```
4. Создал группу admin:  
```
sudo groupadd -f admin
```
5. Добавляем пользователей `vagrant, root, otusadm` в группу `admin`:  
```
usermod otusadm -a -G admin  
usermod root -a -G admin  
usermod vagrant -a -G admin
```
6. 


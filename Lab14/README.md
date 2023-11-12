# Docker, docker-compose, dockerfile
ДЗ:
1) Вопрос №1: Определите разницу между контейнером и образом. Вывод опишите в домашнем задании.
2) Вопрос №2: Можно ли в контейнере собрать ядро?
3) Создайте свой кастомный образ nginx на базе alpine. После запуска nginx должен отдавать кастомную страницу (достаточно изменить дефолтную страницу nginx).
4) Собранный образ необходимо запушить в docker hub и дать ссылку на ваш репозиторий. 
## 1. Ответ на вопрос №1
    Образ - это шаблон / компонент для сборки, открытый для чтения. На базе него создается контейнер. Контейнер - абстракция над образом, открытая на чтение/запись. В ней происходит работа приложения.
## 2. Ответ на вопрос №2
    Собрать ядро можно, но использовать его для загрузки в контейнере не получится - контейнер буде запущен на основе ядра хостовой системы.
## 3. Создание кастомного образа nginx
#### Подготовка окружения
- Устанавливаем и запускаем docker
```s
[root@nginx vagrant]# yum install -y yum-utils
[root@nginx vagrant]# yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
[root@nginx vagrant]# yum install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
[root@nginx vagrant]# systemctl start docker
```
- Устанавливаем Docker-compose  
```sh
[root@nginx vagrant]# curl -L "https://github.com/docker/compose/releases/download/1.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
[root@nginx vagrant]# chmod +x /usr/local/bin/docker-compose
[root@nginx vagrant]# docker-compose --version
```
#### Подготовка Dockerfile и index.hmtl
- Подготовленные файлы [Dockerfile](https://github.com/flazhka/otuslab-homework/blob/master/Lab14/Dockerfile) и [Index.html](https://github.com/flazhka/otuslab-homework/blob/master/Lab14/Index.html)
#### Начало сборки образа
- Выполняем соборку образа в директории с подготовленными файлами Dockerfile и index.hmtl:  
`[root@nginx vagrant]# docker build -t flazhka/nginx_image:image01 .`
- После сборки можно посмотреть на все образы в docker:  
```s
[root@nginx vagrant]# docker images
REPOSITORY            TAG       IMAGE ID       CREATED        SIZE
flazhka/nginx_image   image01   820d3bf02331   1 hour ago     268MB
hello-world           latest    9c7a54a9a43c   6 months ago   13.3kB
```
- Далее выполним запуск контейнера:
```
[root@nginx vagrant]# docker run -d -p 1234:80 flazhka/nginx_image:image01
e42454a45641a1db4c35614a463a8caa1adbf76b0a840fd2378597e2eec68173
[root@nginx vagrant]# docker ps
CONTAINER ID   IMAGE                         COMMAND                  CREATED          STATUS          PORTS                           NAMES
e42454a45641   flazhka/nginx_image:image01   "nginx -g 'daemon of…"   27 seconds ago   Up 10 seconds   443/tcp, 0.0.0.0:1234->80/tcp   dazzling_proskuriakova
```
- Выполнить проверку:  
```html
[root@nginx vagrant]# curl localhost:1234

<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <title>OTUS HomeWork</title>
  </head>
  <body>
    OTUS HomeWork by Docker
  </body>
```
## 4. Публикация собранного образа в docker hub
- Выполняю подключение к docker hub `docker login`, вводим логин и пароль от аккаунта
```s
[root@nginx vagrant]# docker login
Log in with your Docker ID or email address to push and pull images from Docker Hub. If you don't have a Docker ID, head over to https://hub.docker.com/ to create one.

Username: flazhka
Password: 

Login Succeeded
```
- Выполняю публикацию образа `docker push <image>`:  
```s
[root@nginx vagrant]# docker push flazhka/nginx_image:image01
The push refers to repository [docker.io/flazhka/nginx_image]
5f0a3c184c09: Pushed 
0b978374eccd: Pushed 
5445598bd837: Pushed 
27f3e88a746b: Pushed 
cc2447e1835a: Mounted from library/alpine 
image01: digest: sha256:12d9e3c6f385bf485a62fcd88a2b29ac8564b6f89d100c4673ff14b91f0b55f6 size: 1365
```
- Ссылка на репозиторий в Docker hub: 
https://hub.docker.com/repository/docker/flazhka/nginx_image/

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
Устанавливаем и запускаем docker
```sh
[root@nginx vagrant]# yum install -y yum-utils
[root@nginx vagrant]# yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
[root@nginx vagrant]# yum install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
[root@nginx vagrant]# systemctl start docker
```

Устанавливаем Docker-compose
```sh
[root@nginx vagrant]# curl -L "https://github.com/docker/compose/releases/download/1.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
[root@nginx vagrant]# chmod +x /usr/local/bin/docker-compose
[root@nginx vagrant]# docker-compose --version
```

#### Подготовка Dockerfile и index.hmtl
Подготовленные файлы [Dockerfile](https://github.com/flazhka/otuslab-homework/blob/master/Lab14/Dockerfile) и [Index.html](https://github.com/flazhka/otuslab-homework/blob/master/Lab14/Index.html)

#### Начало сборки образа

Выполняем соборку образа в директории с подготовленными файлами Dockerfile и index.hmtl командой:  
`[root@nginx vagrant]# docker build -t flazhka/nginx_image:image01 .`








docker run -d --name nginx_app_container -p 8081:80 nginx_app_image

docker ps

curl localhost:8081


Запускаем новый образ на порту 1234 командой:  
`docker run -d -p 1234:80 kgndsn/nginx_otus:nginx_v1`

- Логинимся на docker, командой docker login

- Push'им образ командой  
`docker push flazhka/nginx_image:image01`









Ссылка на репозиторий в Docker hub: 
https://hub.docker.com/repository/docker/flazhka/nginx_image/

















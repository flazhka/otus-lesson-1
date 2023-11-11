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
Устанавливаем и запускаем docker.
```sh
[root@nginx vagrant]# yum install -y yum-utils
[root@nginx vagrant]# yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
[root@nginx vagrant]# yum install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
[root@nginx vagrant]# systemctl start docker
```

#### Подготовка Dockerfile и index.hmtl
Подготовленные файлы [Dockerfile]()















- Собираем образ в текущей директории командой docker build -t kgndsn/nginx_otus:nginx_v1.

- Запускаем новый образ на порту 1234 командой docker run -d -p 1234:80 kgndsn/nginx_otus:nginx_v1

- Логинимся на docker, командой docker login

- Push'им образ командой docker push kgndsn/nginx_otus:nginx_v1
























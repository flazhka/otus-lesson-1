#  Динамический Web, развертывание веб приложения

#### Домашнее задание: 

Реализована своя комбинации: django + СNoJS + WP
деплой через docker-compose.

К сдаче:
- vagrant стэнд с проброшенными на локалхост портами
- каждый порт на свой сайт


#### Решение:  
В результате выполнения vagrant будет создан виртуальный сервер - DynamicWeb. 
На vm ссылаться три порта с хостовой машины: 8081, 8082, 8083. 
С помощью ansible будут установлены на него docker и docker-compose. После запуска docker-compose файла нём у нас описаны 5 контейнеров: nginx, wordpress, database, node, app. 

Порты 8081, 8082, 8083 мы пробрасываем далее в контейнер nginx, а в нём в конфигурационном файле уже описываем, куда дальше и на какой из сервисов редиректить порты. 

Все конфигурационные файлы описаны в методичке, так что они просто копировались без изменений.

![django](https://github.com/flazhka/otuslab-homework/blob/master/Lab27/1.png)
![СNoJS](https://github.com/flazhka/otuslab-homework/blob/master/Lab27/2.png)
![WP](https://github.com/flazhka/otuslab-homework/blob/master/Lab27/3.png)
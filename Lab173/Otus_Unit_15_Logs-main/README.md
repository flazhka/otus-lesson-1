### Домашнее задание №15 (Логи)
#### Вводные данные:
1. Системой логирования был выбран стек решений от ELK (beats, logstash, elasticsearch, kibana);
2. Вагрант файл разворачивает две виртуальные машины web и log со следующим тюнингом для ВМ log: добавлено дисковое пространство в 10Гб и увеличина оперативаная память до 2 Гб.
3. Написан ansible плейбук для разворачивания конфигурации на ВМ.
___
#### Описание стенда:
Стенд представляет собой две виртуальные машины web и log. На ВМ web развернуты nginx, filebeat, auditbeat. На ВМ log развернуты logstash, elasticsearch и kibana. Виртуальные машины общаются между собой по приватной сети:
web: 192.168.56.240
log: 192.168.56.241
Для каждого приложения из стека ELK создан файл конфигурации.
___
#### Принцип работы:
Стенд настроен следующим образом. Filebeat собирает информацию с папки log на ВМ web, а также из лог файла nginx, и отправляет логи в logstash на ВМ log. Auditbeat отслеживает модуль system и файл конфигурации nginx. Информацию отправляет напрямую в elasticsearch. Logstash прнимает логи от filebeat, фильтрует по timestamp и message, отправляет в elasticsearch. Elasticsearch пишет в базу данных логи. Kibana отображает принимаемую информацию. В конф. файле auditbeat прописана установка дашбордов в kibana.
___
#### Ansible плейбук playbook_main.yml:
Плейбук состоит из 2 PLAY. 1 PLAY добавлет репозиторий elastic на ВМ web, устанавливает nginx, filebeat, auditbeat, копирует конфигурацию из папки template в ВМ web, запускает все службы. 2 PLAY добавляет репозиторий на ВМ log, устанавливает logstash, elasticsearch, kibana, копирует конфигурационные файлы из папки templates в ВМ, запускает все службы. Дополнительно убивается служба firewalld, и прописывается дефолтный маршрут.

Особенности запуска:
- Необходим vpn для установки утилит ELK;
- Для того, чтобы зайти на web страницу kibana, нужно прописать маршрут до ВМ log.
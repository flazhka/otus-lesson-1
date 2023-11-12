# Prometheus - Настройка мониторинга

Настроить дашборд с 4-мя графиками
- память;
- процессор;
- диск;
- сеть.

Настроить на одной из систем:
- zabbix (использовать screen (комплексный экран);
- prometheus - grafana.

В качестве результата прислать скриншот экрана - дашборд должен содержать в названии имя приславшего. 

## Решение

В качестве тестовой инфраструткуре через Vagrant были развернуты 2ве виртуальные машины Server и Client. На сервере были развернуты сервисы Prometheus, Node Exporter и Grafana для выполнения мониторинга собственной нагрузки и нагрузки на Client.

### Установка Prometheus 
Выполняю установку описанную в лекции:

```sh
# Устанавливаем вспомогательные пакеты и скачиваем Prometheus
$ yum update -y
$ yum install wget vim -y
$ wget https://github.com/prometheus/prometheus/releases/download/v2.44.0/prometheus-2.44.0.linux-amd64.tar.gz

# Создаем пользователя и нужные каталоги, настраиваем для них владельцев
$ useradd --no-create-home --shell /bin/false prometheus
$ mkdir /etc/prometheus
$ mkdir /var/lib/prometheus
$ chown prometheus:prometheus /etc/prometheus
$ chown prometheus:prometheus /var/lib/prometheus

# Распаковываем архив, для удобства переименовываем директорию и копируем бинарники в /usr/local/bin
$ tar -xvzf prometheus-2.44.0.linux-amd64.tar.gz
$ mv prometheus-2.44.0.linux-amd64 prometheuspackage
$ cp prometheuspackage/prometheus /usr/local/bin/
$ cp prometheuspackage/promtool /usr/local/bin/
# Меняем владельцев у бинарников
$ chown prometheus:prometheus /usr/local/bin/prometheus
$ chown prometheus:prometheus /usr/local/bin/promtool
# По аналогии копируем библиотеки
$ cp -r prometheuspackage/consoles /etc/prometheus
$ cp -r prometheuspackage/console_libraries /etc/prometheus
$ chown -R prometheus:prometheus /etc/prometheus/consoles
$ chown -R prometheus:prometheus /etc/prometheus/console_libraries

# Создаем файл конфигурации
$ vim /etc/prometheus/prometheus.yml
global:
scrape_interval: 10s
scrape_configs:
- job_name: 'prometheus_master'
scrape_interval: 5s
static_configs:
- targets: ['localhost:9090']
$ chown prometheus:prometheus /etc/prometheus/prometheus.yml

# Настраиваем сервис
$ vim /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target
[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
--config.file /etc/prometheus/prometheus.yml \
--storage.tsdb.path /var/lib/prometheus/ \
--web.console.templates=/etc/prometheus/consoles \
--web.console.libraries=/etc/prometheus/console_libraries
[Install]
WantedBy=multi-user.target
$ systemctl daemon-reload
$ systemctl start prometheus
$ systemctl status prometheus
```

Выполняю проверку работоспособности Prometheus, логинуюсь на сервис prometheus: `http://Server-IP:9090/graph`


### Установка Node Exporter
```sh
# Скачиваем и распаковываем Node Exporter
$ wget https://github.com/prometheus/node_exporter/releases/download/v1.5.0/node_exporter-1.5.0.linux-amd64.tar.gz
$ tar xzfv node_exporter-1.5.0.linux-amd64.tar.gz

# Создаем пользователя, перемещаем бинарник в /usr/local/bin
$ useradd -rs /bin/false nodeusr
$ mv node_exporter-1.5.0.linux-amd64/node_exporter /usr/local/bin/

# Создаем сервис
$ vim /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
After=network.target
[Service]
User=nodeusr
Group=nodeusr
Type=simple
ExecStart=/usr/local/bin/node_exporter
[Install]
WantedBy=multi-user.target

# Запускаем сервис
$ systemctl daemon-reload
$ systemctl start node_exporter
$ systemctl enable node_exporter

# Обновляем конфигурацию Prometheus
$ vim /etc/prometheus/prometheus.yml
global:
scrape_interval: 10s
scrape_configs:
- job_name: 'prometheus_master'
scrape_interval: 5s
static_configs:
- targets: ['localhost:9090']
- job_name: 'node_exporter_centos'
scrape_interval: 5s
static_configs:
- targets: ['localhost:9100']

# Перезапускаем сервис
$ systemctl restart prometheus
```
http://Server-IP:9090/targets
[alt text](/Lab15/01.png?raw=true "Screenshot1")


Для решения использован Vagrant в сочетании с ansible. Установка prometheus, node_exporter, grafana производится из бинарных файлов по техническим причинам. В каталог ansible/files/distrib необходимо скопировать файлы:

    prometheus
    node_exporter
    grafana-9.3.2-1.x86_64.rpm

После установки ПО, из резервной копии в каталоге ansible/files/backup восстанавливается преднастроенная БД Grafana, с требуемым dashboard.
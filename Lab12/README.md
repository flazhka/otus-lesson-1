# Автоматизация администрирования. Ansible

#### Домашнее задание:
Подготовить стенд на Vagrant как минимум с одним сервером. 
На этом сервере используя Ansible необходимо развернуть nginx со следующими условиями: 
- необходимо использовать модуль yum/apt
- конфигурационные файлы должны быть взяты из шаблона jinja2 с
переменными
- после установки nginx должен быть в режиме enabled в systemd
- должен быть использован notify для старта nginx после установки
- сайт должен слушать на нестандартном порту - 8080, для этого использовать переменные в Ansible
* Сделать все это с использованием Ansible роли
- предоставлен Vagrantfile и готовый playbook/роль (инструкция по запуску стенда, если посчитаете необходимым)
- после запуска стенда nginx доступен на порту 8080


## 0. Подготовка и тестирование окружения
Выясняю версии установленного ПО.
```sh
administrator@lablotus01:~$ python3 -V
Python 3.10.12
```
```sh
administrator@lablotus01:~$ ansible --version
ansible 2.10.8
  config file = None
  configured module search path = ['/home/administrator/.ansible/plugins/modules', '/usr/share/ansible/plugins/modules']
  ansible python module location = /usr/lib/python3/dist-packages/ansible
  executable location = /usr/bin/ansible
  python version = 3.10.12 (main, Jun 11 2023, 05:26:28) [GCC 11.4.0]
```
В папке с проектом Lab12 создаю директорию Ansible.  
Создаю файл `hosts` в папке inventory.
```sh
administrator@lablotus01:~/otus_vm/Lab12$ mkdir Ansible
administrator@lablotus01:~/otus_vm/Lab12/Ansible$ vim inventory/hosts
[web]
nginx ansible_host=127.0.0.1 ansible_port=2222 ansible_private_key_file=.vagrant/machines/nginx/virtualbox/private_key
```
Создаю ansible.cfg файл с переменными.
```sh
administrator@lablotus01:~/otus_vm/Lab12Ansible$ vim ansible.cfg
[defaults]
inventory = ./staging/hosts
remote_user = vagrant
host_key_checking = False
retry_files_enabled = False
```
Создаю Vagrantfile файл и запускаю сервер nginx `vagrant up`.  
Выполняю тестирование возможности управления Ansible хостом.
```shell
administrator@lablotus01:~/otus_vm/Lab12/Ansible$ ansible nginx -m ping
nginx | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    },
    "changed": false,
    "ping": "pong"
}
```

## 1. Подгатовка файлов конфигураций, настройка системы
Проверил работоспособноть команд uname -r, sustemctl status firewalld, установил паект epel.
```sh
administrator@lablotus01:~/otus_vm/Lab12/Ansible$ ansible nginx -m command -a "uname -r"
nginx | CHANGED | rc=0 >>
5.14.0-289.el9.x86_64
```
```sh
administrator@lablotus01:~/otus_vm/Lab12/Ansible$ ansible nginx -m systemd -a name=firewalld
nginx | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    },
    "changed": false,
    "name": "firewalld",
    "status": {
        "AccessSELinuxContext": "system_u:object_r:firewalld_unit_file_t:s0",
        "ActiveEnterTimestamp": "Sat 2023-11-04 16:00:35 UTC",
        "ActiveEnterTimestampMonotonic": "107085351",
        "ActiveExitTimestampMonotonic": "0",
        "ActiveState": "active", (ACTIVE)
        ...
```
```sh
administrator@lablotus01:~/otus_vm/Lab12/Ansible$ ansible nginx -m yum -a "name=epel-release state=present" -b
nginx | CHANGED => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    },
    "changed": true,
    "changes": 
{
```
Cоздаю файл epel.yml, запускаю команду ansible-playbook.
```sh
administrator@lablotus01:~/otus_vm/Lab12/Ansible$ ansible-playbook epel.yml
PLAY [Install EPEL Repo] *******************************************************
TASK [Gathering Facts] *********************************************************
ok: [nginx]
TASK [Install EPEL Repo package from standart repo] ****************************
ok: [nginx]
PLAY RECAP ********************************************************************
nginx                      : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```
Запустил команду ansible nginx -m yum -a "name=epel-release state=absent" -b и перезапустил playbook.
```sh
administrator@lablotus01:~/otus_vm/Lab12/Ansible$ ansible-playbook epel.yml                
PLAY [Install EPEL Repo] *******************************************************
TASK [Gathering Facts] *********************************************************
ok: [nginx]
TASK [Install EPEL Repo package from standart repo] ****************************
changed: [nginx]
PLAY RECAP *********************************************************************
nginx                      : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

## 2. Перевод Ansible playbook на role
Создал файл nginx.yml, вывел в консоль теги;
```sh
administrator@lablotus01:~/otus_vm/Lab12/Ansible$ ansible-playbook nginx.yml --list-tags
playbook: nginx.yml
  play #1 (nginx): NGINX | Install and configure NGINX  TAGS: []
      TASK TAGS: [epel-package, nginx-package, packages]
```
Выполняю запуск установки nginx на сервер.
```sh

administrator@lablotus01:~/otus_vm/Lab12/Ansible$ ansible-playbook nginx.yml -t nginx-package
PLAY [NGINX | Install and configure NGINX] *************************************
TASK [Gathering Facts] *********************************************************
ok: [nginx]
TASK [NGINX | Install NGINX package from EPEL Repo] ****************************
changed: [nginx]
PLAY RECAP *********************************************************************
nginx                      : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```
Добавил в файл nginx.yml параметр nginx_listen_port: 8080.  
Создал файл шаблона nginx.conf.j2.  
Добавил handlers и notify в файл плейбука.  
Запустил финальный playbook:

```sh
administrator@lablotus01:~/otus_vm/Lab12/Ansible$ ansible-playbook nginx.yml
PLAY [NGINX | Install and configure NGINX] *************************************
TASK [Gathering Facts] *********************************************************
ok: [nginx]
TASK [NGINX | Install EPEL Repo package from standart repo] ********************
ok: [nginx]
TASK [NGINX | Install NGINX package from EPEL Repo] ****************************
ok: [nginx]
TASK [NGINX | Create NGINX config file from template] **************************
changed: [nginx]
RUNNING HANDLER [reload nginx] *************************************************
changed: [nginx]
PLAY RECAP *********************************************************************
nginx                      : ok=5    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```
Выполняю проверку доступности веб-страницы:

```sh
curl http://192.168.10.170:8080
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
  <title>Welcome to Oracle OS</title>
  <style rel="stylesheet" type="text/css">
```


# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config| #Параметры для создания новой vm
  config.vm.box = "ubuntu/focal64" #Указываем Vagrant box с ос, образ которой будет загружен
  config.vm.box_version = "20220427.0.0" #Указать конкретный номер версии сборки
  config.vm.network "forwarded_port", guest: 80, host: 8090  #Проброс порта с гостевой машины в хост, порт 80 в созданной ВМ будет доступен на порту 8080 хоста
  config.vm.provider "virtualbox" do |vb| #Настройки спецификации ВМ, указывается в отдельном цикле
     vb.memory = "1024" #Указываем количество ОЗУ и ядер процессора
     vb.cpus = "1"
  end

  config.vm.provision "shell", inline: <<-SHELL #Преднастройки созданной ВМ, установка и запуск Веб-сервера Apache2
     sudo apt-get update
     sudo apt-get install -y apache2
  SHELL
end

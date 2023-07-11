# Работа с mdadm
# Задание: 
#- добавить в Vagrant дополнительные диски
#- собрать R0/R5/R10 raid
#- прописать собранный raid в конфиг, чтобы raid собирался при загрузке системы
#- сломать/починить raid
#- создать GPT раздел и 5 партиций и смонтировать их на диск

#В качестве проверки принимается: 
#1)изменненный Vgrantfile
#2)скрипт для создания рейда
#3)конфигурация для автосборки рейда при загрузке
#+ Vagrantfile который сразу собрает систему с подключенным raid


#Добавление в Vagrantfile дополнительного диска
:sata5 => {
	:dfile => './sata5.vdi', #Путь по которому будет создан файл диска
	:size => 100, #Размеер диска в мегабайтах
	:port => 5 #Номер порта на который будет подключен диск
}

#Сборка RAID 0/1/5/10
sudo lshw -short | grep disk #Вывод информации о присутвующих дисках
sudo fdisk -l #Вывод информации о присутвующих дисках
mdadm --zero-superblock --force /dev/sd{b,c,d,e,f} #Зануление суперблоков
mdadm --create --verbose /dev/md0 -l 6 -n 5 /dev/sd{b,c,d,e,f} #Опция -l 6 пределяет уровень raid, -n указывает колличество дисков.
cat /proc/mdstat # Вывод информации о RAID массиве.
mdadm -D /dev/md0


#Создание mdadm.conf 
mdadm --details --scan --verbose # Проверка конфигурации raid
echo "DEVICE partitions" > /etc/mdadm/mdadm.conf
mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm/mdadm.conf 

#Сломать RAID
mdadm /dev/md0 --fail /dev/sde # Перевести диск /dev/sde в ошибку
cat /proc/mdstat # Вывод информации о RAID массиве
mdadm -D /dev/md0 # Вывод информации о RAID массиве

#Починить RAID
mdadm /dev/md0 --remove /dev/sde #Вывести диск sde из raid
mdadm /dev/md0 --add /dev/sde #Добавление нового диска
#Диск должен пройти rebuild
cat /proc/mdstat #Вывод информации о синхронизации raid
mdadm -D /dev/md0 # Вывод информации о RAID массиве

#Создание GPT раздела, 5ть партиций и монтирование на диск
parted -s /dev/md0 mklabel gpt #Создаем раздел GPT на созданный RAID
parted /dev/md0 mkpart primary ext4 #Создание рартиции
for i in $(seq 1 5); do sudo mkfs.ext4 /dev/md0p$i; done #Создание fs на партициях






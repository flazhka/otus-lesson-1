#  Загрузка системы

Работа с загрузчиком

1) Попасть в систему без пароля несколькими способами
2) Установить систему с LVM, после чего переименовать VG
3) Добавить модуль в initrd

### Попасть в систему без пароля несколькими способами
##### Способ 1. init=/bin/sh Работа в однопользовательском режиме
- Открыть консоль vm, запустить виртуальную машину и при выборе ядра для загрузки нажать `e` в данном контексте edit
- Найти строку начинающуюся с `linux16` или до `initrd`
- Добавить `init=/bin/sh`
- Нажать сочетание `Ctrl+x` или `F10`, чтобы выпольнить загрузку с указанной опцией  
- Перемонтировать файловую систему с правами записи: `mount -o remount,rw /`
- Проверить права на запись mount | grep root  
/dev/
- выполнить перезагрузку /sbin/reboot -f

##### Способ 2. rd.break Работа с emergency mode
- Открыть консоль vm, запустить виртуальную машину и при выборе ядра для загрузки нажать `e` в данном контексте edit
- Найти строку начинающуюся с `linux16` или до `initrd`
- Добавить `rd.break`
- Нажать сочетание `Ctrl+x` или `F10`, чтобы выпольнить загрузку с указанной опцией
- mount -o remount,rw /sysroot
- chroot /sysroot
- passwd root
- touch /.autorelabel выполнив touch /.autorelabel

##### Способ 3. rw init=/sysroot/bin/sh
- Открыть консоль vm, запустить виртуальную машину и при выборе ядра для загрузки нажать `e` в данном контексте edit
- Заменāем `ro` на `rw init=/sysroot/bin/sh`
- То же самое что и в прошлом примере, но файловаā система сразу
смонтирована в режим Read-Write

### Установить систему с LVM, после чего переименовать VG

1) Исходим из того, что ос установлена с LVM

- Информация о Volume Group:
```sh
root@labotus02:~# vgs
  VG        #PV #LV #SN Attr   VSize   VFree
  ubuntu-vg   1   1   0 wz--n- <48.00g    0 
```
2) Выполним переименование группы: `ubuntu-vg`
```sh
root@labotus02:~# vgrename ubuntu-vg Otus-Root
  Volume group "ubuntu-vg" successfully renamed to "Otus-Root"
```
- Правим `/etc/fstab`, `/etc/default/grub`, `/boot/grub/grub.cfg`. Везде заменāем старое название LVM на новое.  

! _В случае использования Ubuntu 23.04 достаточно было исправить `grub.cfg`. В остальных местах имя LVM передавалось по UUID._

```sh
echo 'Loading Linux 6.2.0-32-generic ...'
linux /vmlinuz-6.2.0-32-generic root=/dev/mapper/Otus--Root-ubuntu--lv ro quiet splash $vt_handoff
echo 'Loading initial ramdisk ...'
initrd /initrd.img-6.2.0-32-generic
```

3) Выполним генерацию нового конфига для grub.
```sh
root@labotus02:~# dracut -f -v
  .............
dracut: ========================================================================
dracut: *** Creating initramfs image file '/boot/initrd-6.2.0-32-generic' done ***
```

- Перезагружаем ос с новым именем Volume Group и проверяем:
```sh
root@labotus02:~# vgs
  VG        #PV #LV #SN Attr   VSize   VFree
  Otus-Root   1   1   0 wz--n- <48.00g    0 
```
### Добавить модуль в initrd
1) Создадим папку для нового модуля в /usr/lib/dracut/modules.d/
```sh
root@labotus02:~# mkdir /usr/lib/dracut/modules.d/01test
```

2) Поместим 2ва скрипта [module-setup.sh](./module-setup.sh) и [test.sh](test.sh) для вызова и вывода ascii рисунка при загрузке, cделаем файлы исполняемыми chmod +x.

3) Добавим модуль и пересоберм образ initrd.
```sh
root@labotus02:~# dracut -f -v
  ....
dracut: ========================================================================
dracut: *** Creating initramfs image file '/boot/initrd-6.2.0-32-generic' done ***
```
Выполним проверку что модуль был добавлен в образ.
```sh
root@labotus02:~# lsinitrd -m /boot/initramfs-$(uname -r).img | grep test
```

4) Отредактируем `grub.cfg` убрав эти опции: `rghb, quiet`.
```sh
root@labotus02:~# cp /etc/default/grub /etc/default/grub.bak
root@labotus02:~# vim /etc/default/grub
root@labotus02:~# grub-mkconfig -o /boot/grub/grub.cfg
```
После перезагрузки будет загружен созданный модуль, ктороый выведет заготовленный текст в вывод терминала. 


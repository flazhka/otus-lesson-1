#!/bin/bash
echo 'vagrant' | sudo -s yum install -y https://www.elrepo.org/elrepo-release-8.el8.elrepo.noarch.rpm
sudo -s 
yum --enablerepo elrepo-kernel install kernel-ml -y
grub2-mkconfig -o /boot/grub2/grub.cfg
grub2-set-default 0
echo "Grub update done."
shutdown -r now

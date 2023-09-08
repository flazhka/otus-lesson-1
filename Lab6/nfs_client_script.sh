#!/bin/bash
sudo -i
yum -y install nfs-utils
sudo mkdir /nfs_share/
cp /etc/fstab /etc/fstab.bak
echo "192.168.10.30:/nfs_share/ /nfs_share/ nfs vers=3,proto=udp,noauto,x-systemd.automount 0 0" >> /etc/fstab
systemctl daemon-reload
systemctl restart remote-fs.target
exit 0
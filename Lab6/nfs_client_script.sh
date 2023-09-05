#!/bin/bash
sudo -i
yum install -y nfs-utils autofs
mkdir /nfs_share
echo -e '\n[Unit]' \
        '\nDescription="Share automount"' \
        '\nRequires=network-online.target' \
        '\nAfter=network-online.service' \
        '\n[Mount]' \
        '\nWhat=192.168.10.30:/nfs_share/' \
        '\nWhere=nfs_share' \
        '\nType=nfs' \
        '\nDirectoryMode=0766' \
        '\nOptions=rw,noatime,noauto,x-systemd.automount,noexec,nosuid,proto=udp,vers=3' \
        '\n[Install]' \
        '\nWantedBy=multi-user.target' \
        '\n' | tee /etc/systemd/system/nfs_share.automount
echo -e '\n[Unit]' \
        '\nDescription="Share mount"' \
        '\nRequires=network-online.target' \
        '\nAfter=network-online.service' \
        '\n[Automount]' \
        '\nWhere=/mnt/nfs_share' \
        '\nTimeoutIdleSec=10' \
        '\n[Install]' \
        '\nWantedBy=multi-user.target' \
        '\n' | tee /etc/systemd/system/nfs_share.mount
systemctl enable nfs_share.automount --now 
exit 0
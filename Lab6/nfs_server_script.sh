#!/bin/bash
sudo -i
yum install nfs-utils -y
cp /etc/nfs.conf /etc/nfs.conf.bak
sed -i -e 's/# udp=n/udp=y/g' /etc/nfs.conf
systemctl enable --now nfs-server
mkdir -p /nfs_share/upload
echo 'Hi, this is test-file, if this file exist and can be changed - nfs server work correctly' | tee /nfsshare/upload/test_nfs_file.txt
chown -R root:root /nfs_share
chmod 0766 /nfs_share
chown -R nfsnobody:nfsnobody /nfs_share/upload
echo "/nfs_share 192.168.10.31/24(rw,sync,no_wdelay,no_root_squash)" >> /etc/exports
exportfs -a
systemctl enable firewalld --now 
firewall-cmd --add-service={nfs,nfs3,rpc-bind,mountd} --zone=public --permanent
firewall-cmd --add-port=2049/udp --permanent
firewall-cmd --add-port=20048/udp --permanent
firewall-cmd --reload
exit 0
#!/bin/bash
sudo -i
yum -y install nfs-utils
systemctl enable nfs-server --now
mkdir -p /nfs_share/upload
chown -R root:root /nfs_share
chmod 0766 /nfs_share
touch /nfs_share/upload/test_server_file.txt
chown -R nfsnobody:nfsnobody /nfs_share/upload
echo '/nfs_share 192.168.10.0/24(rw,sync,no_root_squash,no_all_squash)' >> /etc/exports
exportfs -a
systemctl restart nfs-server
#
systemctl enable firewalld --now 
firewall-cmd --permanent --zone=public --add-service={nfs,nfs3,ssh,rpc-bind,mountd}
firewall-cmd --permanent --add-port=2049/udp
firewall-cmd --permanent --add-port=20048/udp
firewall-cmd --reload
systemctl restart firewalld
exit 0
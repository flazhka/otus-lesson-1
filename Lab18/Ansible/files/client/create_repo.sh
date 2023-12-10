#!/usr/bin/sh

BORG_PASSPHRASE='Otus1234'
initialize_borg_repo=$(expect -c "
set timeout 5
spawn borg init --encryption=repokey borg@192.168.50.20:/var/backup/
expect \"Enter new passphrase:\"
send \"$BORG_PASSPHRASE\r\"
expect \"Enter same passphrase again:\"
send \"$BORG_PASSPHRASE\r\"
expect \"Do you want your passphrase to be displayed for verification? *\"
send \"y\r\"
expect eof
")
  
echo $initialize_borg_repo

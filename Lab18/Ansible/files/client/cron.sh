#!/usr/bin/sh

date=`date +'%M'`
minute=$(( $(echo $date | awk '{print $1 }') + 1 ))
min=${minute#0}
echo "$min * * * * sh /home/vagrant/create_repo.sh" | crontab -

exit 0

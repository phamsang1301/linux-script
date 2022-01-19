#!/bin/bash

# /root/demo-backup/do_backup.sh
# $1 path $2 ip $3 name $4 type
echo $1 $2 $3 $4
case $4 in
	1)
		if ! [ -d "/home/compression" ]
		then `mkdir /home/compression`
		fi
		tar -czf /home/compression/$3-$(date +"%A").tar.gz -P $1
		rsync -avze ssh /home/compression/$3-$(date +"%A").tar.gz root@server-backup:/home/backup/$2/
		;;
	2)
		rsync -avze ssh $1 root@server-backup:/home/backup/$2/

	
		;;
esac
exit 0

#!/bin/bash

# schedule backup 
# $1 path $2 ip $3 name $4 typ
echo -e "\n\t\t======Schedule Backup ======"
echo -e "\n\t Enter time to schedule backup.\n
	Press Enter if wanna backup with any value of time for each field below.\n
	For entering multi value, each value spread by one \",\""
	
echo -en "\n\t Enter minute (0 - 59): "
read minute
echo -en "\t Enter hour (0 - 23): "
read hour
echo -en "\t Enter day of month (1 - 31): "
read day
echo -en "\t Enter month (1 - 12): "
read month
echo -en "\t Enter day of week (0 - 6) or (Mon - Tue - ...): "
read day_of_w

if test "$minute" == "" 
then	
	minute="*"
fi
if test "$hour" == ""
then
        hour="*"
fi
if test "$month" == ""
then
        month="*"
fi
if test "$day" == ""
then
        day="*"
fi
if test "$day_of_w" == ""
then
        day_of_w="*"
fi

echo "$minute $hour $month $day $day_of_w /root/demo-backup/src/do_backup.sh $1 $2 $3 $4" >> /var/spool/cron/root
echo -e "\t Done \n"
cat /var/spool/cron/root

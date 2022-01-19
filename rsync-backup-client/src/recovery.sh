#!/bin/bash

#/root/demo-backup/recovery.sh
ip=$(/sbin/ip -o -4 addr list ens160 | awk '{print $4}' | cut -d/ -f1)
recovery(){
	if ! [ -d "/home/recovery" ]
	then
		`mkdir /home/recovery`
	fi
	case $1 in 
		0)
			rsync -avzh root@server-backup:/home/backup/$ip/$3-$2.tar.gz /home/recovery/
			;;
		1)
			rsync -avzh root@server-backup:/home/backup/$ip/$3 /home/recovery/
			;;
	esac
}

echo -e "\n\t\t========= Recovery Data ========="

flag=0
while test $flag -eq 0 
do
echo -e "\n\tChoose copy of data: "
echo -e "\t\t1. Monday"
echo -e "\t\t2. Tuesday"
echo -e "\t\t3. Wednesday"
echo -e "\t\t4. Thursday"
echo -e "\t\t5. Friday"
echo -e "\t\t6. Saturday"
echo -e "\t\t7. Sunday"
echo -e "\t\t8. Nearest incremental backup."
echo -e "\t\t0. Back"
echo -en "\t\tYour choice: "
read choice
if test "$choice" == "0" 
then exit
fi
case $choice in
	1)
		echo -en "\n\tEnter data's name: "
		read name

		recovery 0 "Monday" $name
		exit
		;;
	2)
                echo -en "\n\tEnter data's name: "
                read name
		recovery 0 "Tuesday" $name
		exit
		;;
	3)
                echo -en "\n\tEnter data's name: "
                read name
		recovery 0 "Wednesday" $name
		exit
                ;;
	4)

                echo -en "\n\tEnter data's name: "
                read name
		recovery 0 "Thursday" $name
		exit
                ;;
	5)

                echo -en "\n\tEnter data's name: "
                read name
		recovery 0 "Friday" $name
		exit
                ;;
	6)

                echo -en "\n\tEnter data's name: "
                read name
		recovery 0 "Saturday" $name
		exit
                ;;
	7)

                echo -en "\n\tEnter data's name: "
                read name
		recovery 0 "Sunday" $name
		exit
                ;;
	8)
                echo -en "\n\tEnter data's name: "
                read name
                recovery 1 $name
		exit
                ;;
	*)
		echo -e "\t\e[0;31m Wrong input \e[m"
		;;
	
esac	
done

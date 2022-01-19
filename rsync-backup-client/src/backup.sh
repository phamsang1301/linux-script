#!/bin/bash

#/root/demo-backup/backup.sh

ip=$(/sbin/ip -o -4 addr list ens160 | awk '{print $4}' | cut -d/ -f1)


main(){
flag=0
while test $flag -eq 0
do

	echo -e "\n\t\t========== Backup =========="

	while test $flag -eq 0
	do
		echo -e "\n\t\t Backup Type"
		echo -e "\n\t\t 1. Full backup"
		echo -e "\t\t 2. Incremental backup"
		echo -e "\t\t 0. Back"
		echo -en "\t\t Enter backup type: "
		read typ
		if test "$typ" == "0" 
		then
			exit 0
		fi

		echo -en "\t\t Enter data path: "
	        read path
        	tem=$path
        	IFS='/'
        	read -a split <<< "$tem"
        	name=${split[${#split[*]}-1]}

		case $typ in
			1)
				break
				;;
			2)
				break
				;;
			0)
				exit
				;;
			*)
				echo -e "\t\e[0;31m Wrong input \e[m" 
				;;
		esac
		
	done
	echo -e "\n\t\t 1. Backup now"
	echo -e "\t\t 2. Schedule Backup"
	echo -e "\t\t 0. Exit"
	echo -en "\t\t Your choice: "
	read choice
	case $choice in
		1)
			./src/do_backup.sh "$path" $ip $name $typ
			exit
			;;
		2)
			./src/schedule.sh "$path" $ip $name $typ 
			exit
			;;
		0)
			echo -e "\tExited!"
			exit
			;;
		*)
			echo -e "\t\e[0;31m Wrong input \e[m"
			;;
	esac

done	
}
main

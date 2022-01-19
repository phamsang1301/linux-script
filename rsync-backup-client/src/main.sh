#!/bin/bash


flag=0
while test $flag -eq 0 
do	
	echo -e "\n\n\t========= Backup and Recovery ========="
	echo -e "\n\t\t1. Backup"
	echo -e "\t\t2. Recovery"
	echo -e "\t\t0. Exit"
	echo -en "\t\tYour choice: "
	read choice
	case $choice in
		1)
			clear
			./src/backup.sh
			;;
		2)
			clear
			./src/recovery.sh
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



#!/bin/bash
clear
echo "===================================="
echo -e "\tMonitoring System"
echo -e "====================================\n"

echo -n "Input Process ID or Process Name: "
read _input
echo -n "Input interval: "
read _interval

while [[ true ]]; do
	#statements
	clear;
	echo "===================================="
	echo -e "\tMonitoring System"
	echo -e "====================================\n"

	#CPU---------------------------------------------
	echo "CPU: "
	echo "----------------"
	mpstat 1 1 | awk 'NR>2{printf("|%5s | %5s |\n", $4, $6)}' | awk 'NR==1 || NR ==3'
	echo "----------------"
	#END-CPU---------------------------------------------

	#Memory---------------------------------------------
	echo -e "\nMemory: "
	echo "---------------------------------------------------"
	printf "|%s\t|%10s\t|%10s\t|%10s|\n" "Total" "Free" "Used" "Buff/cache"
	echo "---------------------------------------------------"
	top | awk 'NR==4{printf("|%s\t|%10s\t|%10s\t|%10s|\n---------------------------------------------------\n ", $4, $6, $8, $10) ;exit}';
	#END-Memory---------------------------------------------

	echo -e "\nProcess: " $_input 
	echo "---------------------------------------------"
	ps -aux | awk 'NR==1{printf("|%10s\t|%10s\t|%10s\t|\n",$1,$3,$4)}';
	echo "---------------------------------------------"
	ps -aux | awk -v a="$_input" '$2==a{printf("|%10s\t|%10s\t|%10s\t|\n",$1,$3,$4)}'
	# ps -aux | grep -w $_input | awk '{printf("|%10s\t|%10s\t|%10s\t|\n",$1,$3,$4)}'
	echo "---------------------------------------------"

	echo -e "\nHard disk IO"
	# printf "%5s%5s%5s\n" "Device |" "Read |" "Write |"
	echo "----------------------------------------------------------"
	iostat -d 1 2 | awk 'NR>2{printf("|%10s|%10s|%10s|%10s|%10s|\n" ,$1,$3,$4,$5,$6)}'
	echo "----------------------------------------------------------"
	sleep $_interval
done
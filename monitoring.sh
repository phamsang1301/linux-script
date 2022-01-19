#!/bin/bash

echo -n "Input Process ID or Process Name: "
read _input
echo -n "Input interval: "
read _interval

while [[ true ]]; do
	#statements
	ps -aux
	sleep 2;
done
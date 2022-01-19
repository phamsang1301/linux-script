#!/bin/bash

#BIND Administration

################GLOBAL PARAMS################
_zones_dir="/etc/bind/internal-zones"
_named_zone_cfg="/etc/bind/named.conf.internal-zones"

#temporary files
_zone_lists="/tmp/zone_lists.txt"
_record_lists_tmp="/tmp/tmp_record_lists.txt"
_record_lists="/tmp/record_lists.txt"


###############FUNCTION LISTS################
#input validation 
function WrongInput(){
	echo ""
	echo "Invalid Input. Press Enter to continue..."
	read enterKey
}

#prompt
function PressAnyKey(){
	echo ""
	echo "Press Enter to continue..."
	read enterKey
}
#get max zones
function MaxZones(){
	_max_zones="$(grep -c "^" $_zone_lists)"
}

#get max zones
function MaxRecords(){
	_max_records="$(grep -c "^" $_record_lists_tmp)"
}

#get current zone lists
function GetZones(){
	ls -l $_zones_dir | awk '{print $9}' | grep -P ".*[a-zA-Z].db" > $_zone_lists
	#remove all ".db"
	MaxZones
	sed -i 's/.db//g' $_zone_lists
	echo "Current Zone Lists"
	echo "------------------"
	_num=1
	for i in $(cat $_zone_lists)
	do
		if [[ $(($_num % 2)) -eq 0 ]]; then
			echo -en "\e[0;32m"
			echo -ne "$_num.  "
			echo $i
			echo -en "\e[0m"
		else
			echo -ne "$_num.  "
			echo $i
		fi
		((_num = _num + 1))
	done
}
#reload named config
function ReloadBINDCfg(){
	#update new serial id (+1 after each change)
	_current_serial=$(grep -Po "[1-20].*\d(?=.*;Serial)" $_zones_dir/$_zone.db)
	_new_serial=$(($_current_serial + 1))
	sed -i "s/$_current_serial/$_new_serial/g" $_zones_dir/$_zone.db > /dev/null 2>&1
	rndc reload > /dev/null 2>&1
}

#add new record 
function AddRecord(){
	printf "Name: "
	read -r _rname
	printf "Type: "
	read -r _rtype
	printf "Value: "
	read -r _rvalue
	_line=$(grep -nP "$_rname.*$_rtype.*$_rvalue" $_zones_dir/$_zone.db | awk -F ":" '{print $1}')
	if [[ -z $_line ]]; then
		echo "$_rname     IN  $_rtype       $_rvalue" >> $_zones_dir/$_zone.db
		echo "New record has been added."
		ReloadBINDCfg
		PressAnyKey 
	else
		echo "Record exist. Please try with other values."
		PressAnyKey
	fi
}

#remove record
function DeleteRecord(){
	printf "Name: "
	read -r _rname
	printf "Type: "
	read -r _rtype
	printf "Value: "
	read -r _rvalue
	_line=$(grep -nP "$_rname.*$_rtype.*$_rvalue" $_zones_dir/$_zone.db | awk -F ":" '{print $1}')
	if [[ -z $_line ]]; then
		echo "Record doesn't exist. Please try with other record."
		PressAnyKey
	else
		sed -i "$_line d" $_zones_dir/$_zone.db > /dev/null 2>&1
		echo "Record has been deleted."
		ReloadBINDCfg
		PressAnyKey
	fi
}

#record operations
function RecordOperationMenu(){
	echo ""
	echo "1. Add new record"
	echo "2. Delete record"
	echo ""
	echo "0. Exit"
	echo ""
	printf "Choose your option: "
	read -r _ropt
	if ! [[ "$_ropt" =~ ^[0-9]+$ ]]; then
		WrongInput
	elif [[ "$_ropt" == "1" ]]; then
		AddRecord
	elif [[ "$_ropt" == "2" ]]; then
		DeleteRecord
	elif [[ "$_ropt" == "0" ]]; then
		exit 0
	else
		WrongInput
	fi
}

#get zone records
function GetRecords(){
	clear
	echo -ne "Current Seleted Zone: " 
	_zone=$(sed -n "$_opt p" $_zone_lists)
	echo $_zone
	grep -P "\w.*\..*" $_zones_dir/$_zone.db | grep -v "^ \|^@" | sed 's/IN//g' > $_record_lists_tmp
	MaxRecords
	for i in $(seq 1 $_max_records)
	do
		_name=$(sed -n "$i p" $_record_lists_tmp | awk '{print $1}')
		_type=$(sed -n "$i p" $_record_lists_tmp | awk '{print $2}')
		_value=$(sed -n "$i p" $_record_lists_tmp | awk '{print $3}')
		echo "$_name,$_type,$_value" >> $_record_lists
	done
	#print the record lists as table
	sed -i '1iName,Type,Value' $_record_lists
	printTable ","  "$(cat $_record_lists 2> /dev/null)"
	RecordOperationMenu
}

#add new zones
function AddNewZone(){
	printf "Please type a zone name: "
	read -r _zone_name
	printf "Please type IP for this zone: "
	read -r _ip
	grep -o "$_zone_name" $_zone_lists > /dev/null 2>&1
	if [[ $? -eq 0 ]]; then
		echo "Zone exist. Please try with another name."
		PressAnyKey
	else
		_date=$(date "+%y%m%d")
		_serial="0001"
#add zone config file
cat << eof > $_zones_dir/$_zone_name.db
\$TTL 86400
@   IN  SOA     ns1.$_zone_name. admin.$_zone_name. (
        $_date$_serial    ;Serial
        3600            ;Refresh
        1800            ;Retry
        604800          ;Expire
        86400           ;Minimum TTL
)
        IN  NS      ns1.$_zone_name.
        IN  A       $_ip

ns1     IN  A       $_ip
eof

#add zone into named config
cat << eof >>  $_named_zone_cfg
zone "$_zone_name" IN {
        type master;
        file "$_zones_dir/$_zone_name.db";
        allow-update { none; };
};
eof
		echo "New zone has been added."
		#reload naemd without update serial
		rndc reload > /dev/null 2>&1
		PressAnyKey
	fi
}

#delete zone
function DeleteZone(){
	
	printf "Type zone which you want to delete: "
	read -r _rzone
	grep -o "^$_rzone$" $_zone_lists > /dev/null 2>&1
	if [[ $? -eq 0 ]]; then
		#remove zone config file
		rm -rf $_zones_dir/$_rzone.db > /dev/null 2>&1
		#remove named config part
		sed -e "/$_rzone/,+4d" -i $_named_zone_cfg > /dev/null 2>&1
		rndc reload > /dev/null 2>&1 
		echo "Zone '$_rzone' has been deleted."
		PressAnyKey
	else
		echo "Zone doesn't exist. Please try with other name."
		PressAnyKey
	fi
}

#choose option
function ChooseOption(){
	printf "Choose zone id to procced: "
	read -r _opt
	if ! [[ "$_opt" =~ ^[0-9]+$ ]]; then
		WrongInput
	elif [[ $_opt -ge 1 && $_opt -le $_max_zones ]]; then
		GetRecords
	elif [[ "$_opt" == "50" ]]; then
		AddNewZone
	elif [[ "$_opt" == "51" ]]; then
		DeleteZone
	elif [[ "$_opt" == "0" ]]; then
		exit 0
	else
		WrongInput
	fi
}

#draw table
function printTable()
{
    local -r delimiter="${1}"
    local -r data="$(removeEmptyLines "${2}")"

    if [[ "${delimiter}" != '' && "$(isEmptyString "${data}")" = 'false' ]]
    then
        local -r numberOfLines="$(wc -l <<< "${data}")"

        if [[ "${numberOfLines}" -gt '0' ]]
        then
            local table=''
            local i=1

            for ((i = 1; i <= "${numberOfLines}"; i = i + 1))
            do
                local line=''
                line="$(sed "${i}q;d" <<< "${data}")"

                local numberOfColumns='0'
                numberOfColumns="$(awk -F "${delimiter}" '{print NF}' <<< "${line}")"

                # Add Line Delimiter

                if [[ "${i}" -eq '1' ]]
                then
                    table="${table}$(printf '%s#+' "$(repeatString '#+' "${numberOfColumns}")")"
                fi

                # Add Header Or Body

                table="${table}\n"
                local j=1
                for ((j = 1; j <= "${numberOfColumns}"; j = j + 1))
                do
                    table="${table}$(printf '#| %s' "$(cut -d "${delimiter}" -f "${j}" <<< "${line}")")"
                done
                table="${table}#|\n"

                # Add Line Delimiter

                if [[ "${i}" -eq '1' ]] || [[ "${numberOfLines}" -gt '1' && "${i}" -eq "${numberOfLines}" ]]
                then
                    table="${table}$(printf '%s#+' "$(repeatString '#+' "${numberOfColumns}")")"
                fi
                   
            done

            if [[ "$(isEmptyString "${table}")" = 'false' ]]
            then
                echo -e "${table}" | column -s '#' -t | awk '/\+/{gsub(" ", "-", $0)}1' | cut -c 3-
            fi
        fi
    fi
}

function removeEmptyLines()
{
    local -r content="${1}"
   
    echo -e "${content}" | sed '/^\s*$/d'
    
}

function repeatString()
{
    local -r string="${1}"
    local -r numberToRepeat="${2}"

    if [[ "${string}" != '' && "${numberToRepeat}" =~ ^[1-9][0-9]*$ ]]
    then
        local -r result="$(printf "%${numberToRepeat}s")"
        echo -e "${result// /${string}}"
    fi
}

function isEmptyString()
{
    local -r string="${1}"

    if [[ "$(trimString "${string}")" = '' ]]
    then
        echo 'true' && return 0
    fi

    echo 'false' && return 1
}

function trimString()
{
    local -r string="${1}"

    sed 's,^[[:blank:]]*,,' <<< "${string}" | sed 's,[[:blank:]]*$,,'
}

#remove all tmp files
function RemoveTmpFiles(){
	rm -rf $_zone_lists > /dev/null 2>&1
	rm -rf $_record_lists_tmp > /dev/null 2>&1
	rm -rf $_record_lists > /dev/null 2>&1
}

#menu
function Menu(){
	while true
	do
		clear 
		RemoveTmpFiles
		echo "---------------------------------------------"
		echo "BIND DNS Server Administration by VuongNguyen"
		echo "---------------------------------------------"
		GetZones
		echo "------------------"
		echo "50. Add Zone"
		echo "51. Delete Zone"
		echo ""
		echo "0.  Exit"
		echo "---------------------------------------------"
		ChooseOption
	done
}

#main
function Main(){
	Menu
}
#call main function
Main
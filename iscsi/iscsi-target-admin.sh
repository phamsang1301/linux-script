#!/bin/bash

#iSCSI Target Administration

#global parameters
_ver="1.0"
_date=$(date)
_id=$(whoami)
_scriptfile="/root/iscsi-target-admin.sh"

_lun_data_dir="/data-raid5"
_luns_name_file="/tmp/lun_name_file.txt"
_luns_path_file="/tmp/lun_path_file.txt"
_luns_size_file="/tmp/lun_size_file.txt"
_lun_usage_file="/tmp/lun_usage_file.txt"
_luns_info_file="/tmp/lun_info_file.txt"
_tpg_name_file="/tmp/tpg_name.txt"

##########################FUNCTION LISTS##########################
#press enter key
function PressEnterKey() {
    echo "Press Enter to continue..."
    read enterKey
    exec $_scriptfile
}

#input validation
function WrongInput() {
    echo "Invalid Input. Press Enter to continue..."
    read enterKey
}

#save config
function SaveConfigs() {
    targetcli saveconfig >/dev/null
}

#get lun lists
function GetLUNs() {
    #_lun_name
    targetcli /backstores/fileio ls | grep -P "(?<=\[).*(?=\()" | grep -Po "(?<=\- ).*(?=\ \.)" | sed 's/ *$//' >$_luns_name_file
    #_lun_path
    targetcli /backstores/fileio ls | grep -Po "(?<=\[).*(?=\()" | sed 's/ *$//' >$_luns_path_file
    #_lun_size
    targetcli /backstores/fileio ls | grep -Po "(?<=\().*(?=\))" | sed 's/..$//' >$_luns_size_file
    rm -rf $_lun_usage_file >/dev/null 2>&1
    for i in $(cat $_luns_path_file); do
        du -ha $i | awk '{print $1}' >>$_lun_usage_file
    done
    #join temp files into one with , delimiter
    paste -d "," $_luns_name_file $_luns_path_file $_luns_size_file $_lun_usage_file >$_luns_info_file 2>/dev/null
    #add header to the table
    sed -i '1iName,Path,Size,Usage' $_luns_info_file
    echo "LUNs"
    printTable "," "$(cat $_luns_info_file 2>/dev/null)"
}

#get TPGs
function GetTPGs() {
    echo "TPGs"
    echo "-----------------------------"
    targetcli /iscsi ls | grep TPGs | grep -Po "(?<=\- ).*(?=\ \.)"
    echo "-----------------------------"
}

#check lun status
function CheckLUNStatus() {
    for i in $(cat $_luns_name_file); do
        if [[ $_lname == $i ]]; then
            _exist=1
        fi
    done
}

#export lun
function ExportLUN() {
    _tpg_acl="0.0.0.0"
    _date_y_m="$(date "+%Y-%m")"
    printf "Please enter the LUN name which you want to export: "
    read _lname
    CheckLUNStatus
    if [[ "$_exist" == "1" ]]; then
        printf "Please type the TPG name (uniqe name only): "
        read -r _tpg_name
        #printf "Please type the ACL for this LUN [default is: $_tpg_acl]: "
        #read -r _new_tpg_acl
        #if [[ ! -z "$_new_tpg_acl" ]]; then
        #   _tpg_acl=$_new_tpg_acl
        #fi
        _tgp_full="iqn.$_date_y_m.target.$_tpg_name"
        #create tpg
        targetcli /iscsi create $_tgp_full
        targetcli /iscsi/$_tgp_full/tpg1/luns create /backstores/fileio/$_lname
        #targetcli /iscsi/$_tgp_full/tpg1/acls create $_tgp_full:$_tpg_acl
        #disable authentication and write protection
        targetcli /iscsi/$_tgp_full/tpg1 set attribute authentication=0 >/dev/null
        targetcli /iscsi/$_tgp_full/tpg1 set attribute generate_node_acls=1 >/dev/null
        targetcli /iscsi/$_tgp_full/tpg1 set attribute demo_mode_write_protect=0 >/dev/null
    else
        echo "The LUN $_lname doesn't exist. Please try with another name"
    fi
    SaveConfigs
    PressEnterKey
}

#create lun
function CreateLUN() {
    echo -en "\e[92m"
    echo -en "\e[0m"
    #printf "Please type the LUN path [default is $_lun_data_dir]: "
    #read -r _lun_data_dir
    printf "Please type the LUN name: "
    read -r _lname
    printf "Please type the LUN size(GiB): "
    read -r _lsize
    #create lun backend
    targetcli /backstores/fileio create $_lname $_lun_data_dir/$_lname.img $_lsize'GiB'
    SaveConfigs
    PressEnterKey
}

#remove lun
function DeleteLUN() {
    printf "Please type the LUN name which you want to delete: "
    read -r _lname
    #delete lun
    targetcli /backstores/fileio delete $_lname
    SaveConfigs
    PressEnterKey
}

#remove export
function UnMap() {
    printf "Please type the TPG name: "
    read -r _tpg_name
    targetcli /iscsi delete $_tpg_name
    SaveConfigs
    PressEnterKey
}

#tpg detail
function TPGDetail() {
    printf "Please type the TPG name: "
    read -r _tpg_name
    targetcli /iscsi ls $_tpg_name
    SaveConfigs
    PressEnterKey
}

#raw configs
function RawConfigs() {
    targetcli ls
    PressEnterKey
}

#draw table
function printTable() {
    local -r delimiter="${1}"
    local -r data="$(removeEmptyLines "${2}")"

    if [[ "${delimiter}" != '' && "$(isEmptyString "${data}")" = 'false' ]]; then
        local -r numberOfLines="$(wc -l <<<"${data}")"

        if [[ "${numberOfLines}" -gt '0' ]]; then
            local table=''
            local i=1

            for ((i = 1; i <= "${numberOfLines}"; i = i + 1)); do
                local line=''
                line="$(sed "${i}q;d" <<<"${data}")"

                local numberOfColumns='0'
                numberOfColumns="$(awk -F "${delimiter}" '{print NF}' <<<"${line}")"

                # Add Line Delimiter

                if [[ "${i}" -eq '1' ]]; then
                    table="${table}$(printf '%s#+' "$(repeatString '#+' "${numberOfColumns}")")"
                fi

                # Add Header Or Body

                table="${table}\n"
                local j=1
                for ((j = 1; j <= "${numberOfColumns}"; j = j + 1)); do
                    table="${table}$(printf '#| %s' "$(cut -d "${delimiter}" -f "${j}" <<<"${line}")")"
                done
                table="${table}#|\n"

                # Add Line Delimiter

                if [[ "${i}" -eq '1' ]] || [[ "${numberOfLines}" -gt '1' && "${i}" -eq "${numberOfLines}" ]]; then
                    table="${table}$(printf '%s#+' "$(repeatString '#+' "${numberOfColumns}")")"
                fi

            done

            if [[ "$(isEmptyString "${table}")" = 'false' ]]; then
                echo -e "${table}" | column -s '#' -t | awk '/\+/{gsub(" ", "-", $0)}1' | cut -c 3-
            fi
        fi
    fi
}

function removeEmptyLines() {
    local -r content="${1}"

    echo -e "${content}" | sed '/^\s*$/d'

}

function repeatString() {
    local -r string="${1}"
    local -r numberToRepeat="${2}"

    if [[ "${string}" != '' && "${numberToRepeat}" =~ ^[1-9][0-9]*$ ]]; then
        local -r result="$(printf "%${numberToRepeat}s")"
        echo -e "${result// /${string}}"
    fi
}

function isEmptyString() {
    local -r string="${1}"

    if [[ "$(trimString "${string}")" = '' ]]; then
        echo 'true' && return 0
    fi

    echo 'false' && return 1
}

function trimString() {
    local -r string="${1}"

    sed 's,^[[:blank:]]*,,' <<<"${string}" | sed 's,[[:blank:]]*$,,'
}

#menu
function Menu() {
    while true; do
        clear
        echo "Current user: $_id @ $_date"
        echo "Script by VuongNguyen             Version: $_ver"
        echo "------------------------------------------------"
        echo "1. Create LUN"
        echo "2. Export LUN"
        echo "3. Delete LUN"
        echo "4. UnMap LUN"
        echo "5. TPG Detail"
        echo ""
        echo "10. Raw Configs"
        echo ""
        echo "0. Exit"
        echo "------------------------------------------------"
        GetLUNs
        GetTPGs
        printf "Choose your option: "
        read _opt
        if ! [[ "$_opt" =~ ^[0-9]+$ ]]; then
            WrongInput
        elif [[ "$_opt" -eq "1" ]]; then
            CreateLUN
        elif [[ "$_opt" -eq "2" ]]; then
            ExportLUN
        elif [[ "$_opt" -eq "3" ]]; then
            DeleteLUN
        elif [[ "$_opt" -eq "4" ]]; then
            UnMap
        elif [[ "$_opt" -eq "5" ]]; then
            TPGDetail
        elif [[ "$_opt" -eq "10" ]]; then
            RawConfigs
        elif [[ "$_opt" -eq "0" ]]; then
            exit 0
        else
            WrongInput
        fi
    done
}

##########################FUNCTION LISTS##########################
Menu

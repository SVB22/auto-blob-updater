#!/bin/bash 
#
# CI Runner Script for Generation of blobs
#

setup_makefiles="/mnt/1/aicp/device/xiaomi/davinci/setup-makefiles.sh"
extract_files="/mnt/1/aicp/device/xiaomi/davinci/extract-files.sh"

website_curl()
{
    wget https://github.com/XiaomiFirmwareUpdater/miui-updates-tracker/tree/master/stable_recovery -O page.htm
}

function count_links()
{
	mapfile -t device_link < <( cat page.htm | grep -E "href=\"*.*yml\"" | cut -d "<" -f3 | cut -d " " -f4| cut -d "\"" -f2 )
}

function select_link()
{
    select id in "${device_link[@]}" 
    do
        case "$device_nr" in
            *)  yaml_file=${id}
	        			echo "You chose $yaml_file"
					yaml_load
					return 0
        esac
    done
}

function yaml_load()
{
    local raw_file="https://raw.githubusercontent.com/XiaomiFirmwareUpdater/miui-updates-tracker/master/stable_recovery/$yaml_file"
    wget $raw_file 	
    yaml_parser
}

function yaml_parser() 
{
     mapfile -t git_links < <(grep -i "download" $yaml_file | cut -d " " -f2)
     select git_id in "${git_links[@]}"
     do
        case "$link_nr" in
            *) export git_file=${git_id[$link_nr]}
               export ota_filename=$(echo  $git_file | cut -d "/" -f5)
	       echo "you chose this $ota_filename"
	       rom_loader	
	       return 0
        esac
     done

    exit
}

function rom_loader()
{
    wget $git_file
}

function dumpyara() {
    wget https://raw.githubusercontent.com/AndroidDumps/dumpyara/master/dumpyara.sh
    chmod 755 dumpyara.sh
    ./dumpyara.sh $ota_filename
    ota_file=$(basename $ota_filename .zip)
    rm $ota_filename
    cd working/${ota_file} 
    mv vendor system
    bash $setup_makefiles system/
    bash $extract_files system/
    exit
}


# =====================================================================================
# main
# =====================================================================================

website_curl
count_links
if [ ${#device_link[@]} -eq 0 ] 
then
	exit 1
else 
	select_link
	dumpyara
fi

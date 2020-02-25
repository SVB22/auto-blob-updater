#!/bin/bash -xv 
#
# CI Runner Script for Generation of blobs
#

website_curl()
{
    wget https://github.com/XiaomiFirmwareUpdater/xiaomifirmwareupdater.github.io/tree/master/data/vendor/latest -O page.htm
}

function count_links()
{
    mapfile -t device_link < <( cat page.htm | grep -E "href=\"*.*yml\""| cut -d "<" -f3 | cut -d " " -f3 | cut -d "\"" -f2)
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
    local raw_file="https://raw.githubusercontent.com/XiaomiFirmwareUpdater/xiaomifirmwareupdater.github.io/master/data/vendor/latest/$yaml_file"
    wget $raw_file 	
    yaml_parser
}

function yaml_parser() 
{
     mapfile -t git_links < <(grep -i "github" $yaml_file | cut -d " " -f6)
     select git_id in "${git_links[@]}"
     do
        case "$link_nr" in
            *) export git_file=${git_id[$link_nr]}
               export ota_filename=$(echo  $git_file | cut -d "/" -f9)
	       rom_loader	
	       return 0
        esac
     done

    exit
}

rom_loader()
{
    wget $git_file
    unzip $ota_filename
}

dec_brotli() {
    echo "Decompressing brotli....."
    brotli --decompress  system.new.dat.br > /dev/null 2>&1
    brotli --decompress vendor.new.dat.br > /dev/null 2>&1
    echo "Decompressed successfully....."
}

sdatimg() {
    echo "Converting to img....."
    wget https://raw.githubusercontent.com/xpirt/sdat2img/master/sdat2img.py -O sdat2img.py
    python3 sdat2img.py system.transfer.list system.new.dat > /dev/null 2>&1
    python3 sdat2img.py vendor.transfer.list vendor.new.dat vendor.img > /dev/null 2>&1
}

extract() {
    echo "Extracting the img's....."
    7z x system.img -y -osystem > /dev/null 2>&1
    7z x vendor.img -y -ovendor > /dev/null 2>&1
    echo "Finished successfully"
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
  	dec_brotli
	sdatimg
	extract
fi

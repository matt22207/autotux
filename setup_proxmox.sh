#!/bin/bash

# initial setup script for proxmox server.. to install this script from github, run:
#
# apt update && apt install git
# git clone https://github.com/matt22207/autotux.git
# cd autotux
# chmod +x setup_proxmox.sh
# bash ./setup_proxmox.sh

source ./config.sh
source ./functions.sh

# create a directory for any backups
echo "Checking for ${BACKUP_PATH}"
if [ ! -d ${BACKUP_PATH} ]; then
    echo "Backup directory not found. Creating now."
    mkdir ${BACKUP_PATH}
fi

if ! ${SUDO} cat /etc/apt/sources.list.d/pve-enterprise.list | grep "#deb https://enterprise.proxmox.com/debian/pve bullseye pve-enterprise"; then
    echo
    echo "disable enterprise repo since we are running unlicensed proxmox"
    echo

    cp /etc/apt/sources.list.d/pve-enterprise.list "${BACKUP_PATH}/pve-enterprise.list_$(date +%Y%m%d_%H%M%S)"
    commmentLineInFile 'deb https:\/\/enterprise\.proxmox\.com\/debian\/pve bullseye pve-enterprise' "/etc/apt/sources.list.d/pve-enterprise.list"
fi

echo
echo "adding public repo since we are running unlicensed proxmox"
echo

appendLineToFile '# PVE pve-no-subscription repository provided by proxmox.com,' '/etc/apt/sources.list'
appendLineToFile '# NOT recommended for production use' '/etc/apt/sources.list'
appendLineToFile 'deb http://download.proxmox.com/debian/pve bullseye pve-no-subscription' '/etc/apt/sources.list'

echo
echo "Running: ${PACKAGE_MANAGER_BIN} ${PACKAGE_MANAGER_UPDATE_CMD}"
echo
${PACKAGE_MANAGER_BIN} ${PACKAGE_MANAGER_UPDATE_CMD}


exit 0

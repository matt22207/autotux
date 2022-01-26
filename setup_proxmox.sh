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

if  [ "${OS_ID_LIKE}" != "arch" ]; then
    echo
    echo "Running: ${PACKAGE_MANAGER_BIN} ${PACKAGE_MANAGER_UPGRADE_CMD}"
    echo
    ${PACKAGE_MANAGER_BIN} ${PACKAGE_MANAGER_UPGRADE_CMD}

    echo
    echo "Running: ${PACKAGE_MANAGER_BIN} ${PACKAGE_MANAGER_AUTOREMOVE_CMD}"
    echo
    ${PACKAGE_MANAGER_BIN} ${PACKAGE_MANAGER_AUTOREMOVE_CMD}
fi

echo
echo "Downloading Ubuntu"
echo
wget -c -P /var/lib/vz/template/iso https://releases.ubuntu.com/21.10/ubuntu-21.10-desktop-amd64.iso


exit 0

echo 
echo "creating VM"
echo
qm destroy 100
qm create 100 --agent 1 --bios seabios --boot order=ide2\;scsi0 --cpu cputype=host --cores 16 --sockets 1 --ide2 local:iso/ubuntu-21.10-desktop-amd64.iso,media=cdrom --machine q35 --memory 10240 --name minisBuntu --net0 virtio=3A:0A:65:11:25:9A,bridge=vmbr0,firewall=1 --numa 0 --ostype l26 --scsi0 local-lvm:vm-100-disk-0,cache=writeback,size=32G,ssd=1 --scsihw virtio-scsi-pci --tpmstate0 local-lvm:vm-100-disk-1,size=4M,version=v2.0
pvesm alloc local-lvm 100 vm-100-disk-0 32G
pvesm alloc local-lvm 100 vm-100-disk-1 4M
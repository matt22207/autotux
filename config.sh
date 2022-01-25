#!/bin/bash

# config variables. do not run directly. use setup.sh / setup_proxmox.sh

BACKUP_PATH=~/.setup_backups
GRUB_CFG_PATH=/etc/default/grub
VFIO_CFG_PATH=/etc/dracut.conf.d/vfio.conf
LIBVIRT_CFG_PATH=/etc/libvirt/libvirtd.conf
QEMU_CFG_PATH=/etc/libvirt/qemu.conf
PACKAGES=""
UPDATE_GRUB_CMD="update-grub"

#use debian by default
PACKAGE_MANAGER_BIN="sudo apt"
PACKAGE_MANAGER_INSTALL_CMD="install -y"
PACKAGE_MANAGER_UPDATE_CMD="update -y && sudo apt upgrade -y && sudo apt autoremove -y"
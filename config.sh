#!/bin/bash

# config variables. do not run directly. use setup.sh / setup_proxmox.sh

SUDO=""
if [ "$(whoami)" != "root" ]; then
    echo "not root"
    SUDO="sudo"
else
    echo "root"
fi
echo "sudo: $SUDO"


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

# OS Detection: https://github.com/T-vK/MobilePassThrough/blob/unattended-win-install/scripts/utils/common/tools/distro-info

if [ -f /etc/os-release ]; then
    # echo "found /etc/os-release"
    # Arch, freedesktop.org and systemd
    . /etc/os-release
    OS_NAME=$NAME
    OS_ID_LIKE=$ID_LIKE
    OS_VER=$VERSION_ID
elif [ -f /etc/debian_version ]; then
    # echo "older debian"
    # Older Debian/Ubuntu/etc.
    OS_NAME=Debian
    OS_ID_LIKE=$OS
    OS_VER=$(cat /etc/debian_version)
else
    # echo "fallback to uname"
    # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
    OS_NAME=$(uname -s)
    OS_ID_LIKE=$OS
    OS_VER=$(uname -r)
fi

echo "OS_NAME: $OS_NAME"
echo "OS_ID_LIKE : $OS_ID_LIKE"
echo "OS_VER: $OS_VER"

if  [ "${OS_ID_LIKE}" = "arch" ]; then
    echo "Found Arch!"

    PACKAGE_MANAGER_BIN="yay"
    PACKAGE_MANAGER_INSTALL_CMD="-S --noconfirm --needed"
    PACKAGE_MANAGER_UPDATE_CMD="-Syyu --noconfirm"
    #PACKAGE_MANAGER_SEARCH_CMD="-Ss"
    UPDATE_GRUB_CMD="grub-mkconfig -o /boot/grub/grub.cfg"
fi
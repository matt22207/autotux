#!/bin/bash

# wget -O - https://raw.githubusercontent.com/matt22207/autotux/main/setup.sh | bash

BACKUP_PATH=~/.setup_backups
GRUB_CFG_PATH=/etc/default/grub
VFIO_CFG_PATH=/etc/dracut.conf.d/vfio.conf
APT_PACKAGES=""

# create a directory for any backups
mkdir ${BACKUP_PATH}

# https://itsfoss.com/fedora-dark-mode/
gsettings set org.gnome.desktop.interface gtk-theme Adwaita-dark
gsettings set org.gnome.desktop.interface gtk-theme Yaru-dark

sudo apt update -y && sudo apt upgrade -y
#sudo apt full-upgrade

APT_PACKAGES+="gnome-tweaks neofetch git openssh-server net-tools htop timeshift flatpak "

# KVM thin provisioning tools, virt-sparsify - https://www.certdepot.net/kvm-thin-provisioning-tip/
APT_PACKAGES+="libguestfs-tools "

# https://cockpit-project.org/running.html#ubuntu
APT_PACKAGES+="cockpit cockpit-machines cockpit-pcp "

# https://flatpak.org/setup/Ubuntu/
APT_PACKAGES+="flatpak gnome-software-plugin-flatpak "

# Setup libvirt for Single GPU Passhthrough - https://gitlab.com/risingprismtv/single-gpu-passthrough/-/wikis/4)-Configuring-of-Libvirt
APT_PACKAGES+="qemu-kvm libvirt-clients libvirt-daemon-system bridge-utils virt-manager ovmf "

sudo apt install -y $APT_PACKAGES


sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
sudo flatpak update
sudo flatpak install flathub org.gnome.Extensions

sudo snap refresh
# latest barrier is in snap. doesn't support Wayland yet
sudo snap install barrier

## PAUSE HERE TO REBOOT

# TODO : Grub font size
# https://vietlq.github.io/2019/09/22/make-grub-font-size-bigger/


# modify grub via: https://github.com/T-vK/MobilePassThrough/blob/master/utils/Ubuntu/21.04/kernel-param-utils

GRUB_UPDATE_REQUIRED=0
cp ${GRUB_CFG_PATH} "${BACKUP_PATH}/grub_$(date +%Y%m%d_%H%M%S)"

function addKernelParam() {
    if ! sudo cat "$GRUB_CFG_PATH" | grep "GRUB_CMDLINE_LINUX=" | grep --quiet "$1"; then
        sudo sed -i "s/^GRUB_CMDLINE_LINUX=\"/&$1 /" "$GRUB_CFG_PATH"
        echo "addKernelParam: Added \"$1\" to GRUB_CMDLINE_LINUX in $GRUB_CFG_PATH"
        GRUB_UPDATE_REQUIRED=1
    else
        echo "addKernelParam: No action required. \"$1\" already exists in GRUB_CMDLINE_LINUX of $GRUB_CFG_PATH"
    fi
}

echo "Adding kernel parameters..."
# Docs: https://www.kernel.org/doc/Documentation/admin-guide/kernel-parameters.txt
# More docs: https://lwn.net/Articles/252826/
# https://www.kernel.org/doc/Documentation/x86/x86_64/boot-options.txt
echo "Adding kernel parameters to enable IOMMU on Intel/AMD CPUs..."

# https://gitlab.com/risingprismtv/single-gpu-passthrough/-/wikis/2)-Editing-GRUB
addKernelParam "iommu=pt"
addKernelParam "intel_iommu=on" # enable Intel VT-D   ;# using "intel_iommu=on,igfx_off" iGPU gets no iommu group...
addKernelParam "apparmor=1"
addKernelParam "security=apparmor"
addKernelParam "udev.log_priority=3"

echo "Checking if GRUB_UPDATE_REQUIRED == 1 : ${GRUB_UPDATE_REQUIRED}"

if  [ ${GRUB_UPDATE_REQUIRED} -eq 1 ]; then
    echo "Applying the kernel parameter changes..."
    sudo update-grub
else
    echo "No changes to kernel parameters..."
fi
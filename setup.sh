#!/bin/bash

# wget -O - https://raw.githubusercontent.com/matt22207/autotux/main/setup.sh | bash

BACKUP_PATH=~/.setup_backups
GRUB_CFG_PATH=/etc/default/grub
VFIO_CFG_PATH=/etc/dracut.conf.d/vfio.conf
LIBVIRT_CFG_PATH=/etc/libvirt/libvirtd.conf
QEMU_CFG_PATH=/etc/libvirt/qemu.conf
PACKAGES=""

#use debian by default
PACKAGE_MANAGER_BIN="sudo apt"
PACKAGE_MANAGER_INSTALL_CMD="install -y"
PACKAGE_MANAGER_UPDATE_CMD="update -y && sudo apt upgrade -y && sudo apt autoremove -y"

# OS Detection: https://github.com/T-vK/MobilePassThrough/blob/unattended-win-install/scripts/utils/common/tools/distro-info

if [ -f /etc/os-release ]; then
    # Arch, freedesktop.org and systemd
    . /etc/os-release
    OS_NAME=$NAME
    OS_ID_LIKE=$ID_LIKE
fi

echo "OS_NAME: $OS_NAME"
echo "OS_ID_LIKE : $OS_ID_LIKE"

if  [ "${OS_ID_LIKE}" = "arch" ]; then
    echo "Found Arch!"

    PACKAGE_MANAGER_BIN="yay"
    PACKAGE_MANAGER_INSTALL_CMD="-S --noconfirm --needed"
    PACKAGE_MANAGER_UPDATE_CMD="-Syyu --noconfirm"
    #PACKAGE_MANAGER_SEARCH_CMD="-Ss"
fi

# create a directory for any backups
echo "Checking for ${BACKUP_PATH}"
if [ ! -d ${BACKUP_PATH} ]; then
    echo "Backup directory not found. Creating now."
    mkdir ${BACKUP_PATH}
fi

# https://itsfoss.com/fedora-dark-mode/
gsettings set org.gnome.desktop.interface gtk-theme Adwaita-dark
#gsettings set org.gnome.desktop.interface gtk-theme Yaru-dark

echo
echo "Running: ${PACKAGE_MANAGER_BIN} ${PACKAGE_MANAGER_UPDATE_CMD}"
echo
${PACKAGE_MANAGER_BIN} ${PACKAGE_MANAGER_UPDATE_CMD}
#sudo apt update -y && sudo apt upgrade -y && sudo apt autoremove -y
#sudo apt full-upgrade

PACKAGES+="gnome-tweaks neofetch git net-tools htop timeshift flatpak firefox chrome-gnome-shell screen nvidia-settings mangohud goverlay "
if  [ "${OS_ID_LIKE}" = "arch" ]; then
    PACKAGES+="sysstat python-pip guestfs-tools "
    # KVM thin provisioning tools, virt-sparsify - https://www.certdepot.net/kvm-thin-provisioning-tip/
    # TODO SINCE BROKEN: PACKAGES+="guestfs-tools "
else
    PACKAGES+="systat python3-pip openssh-server "
    PACKAGES+="nvidia-driver-470 nvidia-utils-470 "
    # KVM thin provisioning tools, virt-sparsify - https://www.certdepot.net/kvm-thin-provisioning-tip/
    PACKAGES+="libguestfs-tools "
fi

# TODO: remove xserver-xorg-video-nouveau

echo
echo "Running: ${PACKAGE_MANAGER_BIN} ${PACKAGE_MANAGER_INSTALL_CMD} ${PACKAGES}"
echo
${PACKAGE_MANAGER_BIN} ${PACKAGE_MANAGER_INSTALL_CMD} ${PACKAGES}
exit 0

# https://cockpit-project.org/running.html#ubuntu
PACKAGES+="cockpit cockpit-machines cockpit-pcp "

# https://flatpak.org/setup/Ubuntu/
PACKAGES+="flatpak gnome-software-plugin-flatpak "

# Setup libvirt for Single GPU Passhthrough - https://gitlab.com/risingprismtv/single-gpu-passthrough/-/wikis/4)-Configuring-of-Libvirt
PACKAGES+="qemu-kvm libvirt-clients libvirt-daemon-system bridge-utils virt-manager ovmf driverctl "

sudo apt install -y $PACKAGES

wget "https://launchpad.net/veracrypt/trunk/1.24-update7/+download/veracrypt-1.24-Update7-Ubuntu-21.10-amd64.deb" -O /tmp/veracrypt-1.24-Update7-Ubuntu-21.10-amd64.deb
sudo apt install /tmp/veracrypt-1.24-Update7-Ubuntu-21.10-amd64.deb

sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
sudo flatpak update -y
sudo flatpak install -y flathub org.gnome.Extensions

# https://itsfoss.com/flatseal/
sudo flatpak install -y flathub com.github.tchx84.Flatseal

sudo snap refresh
# latest barrier is in snap. doesn't support Wayland yet
sudo snap install barrier
sudo snap remove firefox

# install latest lutris - https://lutris.net/downloads
sudo add-apt-repository ppa:lutris-team/lutris
sudo apt update
sudo apt install lutris

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
# enable Intel VT-D   ;# using "intel_iommu=on,igfx_off" iGPU gets no iommu group...
addKernelParam "iommu=pt"
addKernelParam "intel_iommu=on" 
addKernelParam "apparmor=1"
addKernelParam "security=apparmor"
addKernelParam "udev.log_priority=3"

# TODO: remove quiet from grub

echo "Checking if GRUB_UPDATE_REQUIRED == 1 : ${GRUB_UPDATE_REQUIRED}"

if  [ ${GRUB_UPDATE_REQUIRED} -eq 1 ]; then
    echo "Applying the kernel parameter changes... *** RESTART NEEDED ***"
    sudo update-grub
else
    echo "No changes to kernel parameters..."
fi

# Step 4 : https://gitlab.com/risingprismtv/single-gpu-passthrough/-/wikis/4)-Configuring-of-Libvirt

function appendLineToFile() {
    echo "appending : [ $1 ] to $2"
    if ! sudo cat "$2" | grep "$1"; then
        echo "$1" | sudo tee -a $2
    else 
        echo "-- No changes needed"
    fi
}

function replaceLineInFile() {
    echo "replacing : [ $1 ] with [ $2 ] in $3"
    if sudo cat "$3" | grep "$1"; then    
        sudo sed -i "s/^$1/$2/" "$3"
    else 
        echo "-- No changes needed"
    fi
}

function uncommmentLineFromFile() {
    replaceLineInFile "#$1" "$1" "$2"
}

cp ${LIBVIRT_CFG_PATH} "${BACKUP_PATH}/libvirtd.conf_$(date +%Y%m%d_%H%M%S)"

uncommmentLineFromFile 'unix_sock_group = "libvirt"' "$LIBVIRT_CFG_PATH"
uncommmentLineFromFile 'unix_sock_rw_perms = "0770"' "$LIBVIRT_CFG_PATH"

appendLineToFile 'log_filters="1:qemu"' "$LIBVIRT_CFG_PATH"
appendLineToFile 'log_outputs="1:file:/var/log/libvirt/libvirtd.log"' "$LIBVIRT_CFG_PATH"

sudo usermod -a -G libvirt $(whoami)
sudo systemctl start libvirtd
sudo systemctl enable libvirtd

sudo cp ${QEMU_CFG_PATH} "${BACKUP_PATH}/qemu.conf_$(date +%Y%m%d_%H%M%S)"
replaceLineInFile '#user = "root"' "user = '$(whoami)'" "$QEMU_CFG_PATH"
replaceLineInFile '#group = "root"' "group = '$(whoami)'" "$QEMU_CFG_PATH"

echo "restarting libvirtd"
sudo systemctl restart libvirtd
sudo usermod -a -G kvm,libvirt $(whoami)

# Step 7: https://gitlab.com/risingprismtv/single-gpu-passthrough/-/wikis/6)-Preparation-and-placing-of-ROM-file

echo "setting up vgabios rom"
sudo mkdir /usr/share/vgabios
sudo wget https://raw.githubusercontent.com/matt22207/autotux/main/TU104.rom -O /usr/share/vgabios/TU104.rom
sudo chmod -R 660 /usr/share/vgabios/TU104.rom
sudo chown $(whoami):$(whoami) /usr/share/vgabios/TU104.rom
#!/bin/bash

# wget -O - https://raw.githubusercontent.com/matt22207/autotux/main/setup.sh | bash
# 
# or
# 
# git clone https://github.com/matt22207/autotux.git
# cd autotux
# git pull; bash ./setup.sh
#
# TODO add execution bit to setup.sh

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
    UPDATE_GRUB_CMD="grub-mkconfig -o /boot/grub/grub.cfg"
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

gsettings set org.gnome.settings-daemon.plugins.media-keys screen-brightness-down "['Launch5']"
gsettings set org.gnome.settings-daemon.plugins.media-keys screen-brightness-up "['Launch6']"
gsettings set org.gnome.settings-daemon.plugins.media-keys suspend "['<Alt><Super>Eject']"

echo
echo "Running: ${PACKAGE_MANAGER_BIN} ${PACKAGE_MANAGER_UPDATE_CMD}"
echo
${PACKAGE_MANAGER_BIN} ${PACKAGE_MANAGER_UPDATE_CMD}
#sudo apt update -y && sudo apt upgrade -y && sudo apt autoremove -y
#sudo apt full-upgrade

PACKAGES+="gnome-tweaks neofetch git net-tools htop timeshift deja-dup flatpak firefox chrome-gnome-shell screen nvidia-settings mangohud goverlay "
if  [ "${OS_ID_LIKE}" = "arch" ]; then
    PACKAGES+="sysstat python-pip veracrypt lutris protonup protonup-qt gamemode baobab "
    # Setup libvirt for Single GPU Passhthrough - https://gitlab.com/risingprismtv/single-gpu-passthrough/-/wikis/4)-Configuring-of-Libvirt
    PACKAGES+="virt-manager qemu vde2 dnsmasq bridge-utils ovmf iptables-nft nftables ebtables "

    # setup wine dependencies : https://github.com/lutris/docs/blob/master/WineDependencies.md
    PACKAGES+="wine giflib lib32-giflib libpng lib32-libpng libldap lib32-libldap gnutls lib32-gnutls mpg123 lib32-mpg123 openal lib32-openal v4l-utils lib32-v4l-utils libpulse lib32-libpulse libgpg-error lib32-libgpg-error alsa-plugins lib32-alsa-plugins alsa-lib lib32-alsa-lib libjpeg-turbo lib32-libjpeg-turbo sqlite lib32-sqlite libxcomposite lib32-libxcomposite libxinerama lib32-libgcrypt libgcrypt lib32-libxinerama ncurses lib32-ncurses opencl-icd-loader lib32-opencl-icd-loader libxslt lib32-libxslt libva lib3vgiflib lib32-giflib libpng lib32-libpng libldap lib32-libldap gnutls lib32-gnutls mpg123 lib32-mpg123 openal lib32-openal v4l-utils lib32-v4l-utils libpulse lib32-libpulse libgpg-error lib32-libgpg-error alsa-plugins lib32-alsa-plugins alsa-lib lib32-alsa-lib libjpeg-turbo lib32-libjpeg-turbo sqlite lib32-sqlite libxcomposite lib32-libxcomposite libxinerama lib32-libgcrypt libgcrypt lib32-libxinerama ncurses lib32-ncurses opencl-icd-loader lib32-opencl-icd-loader libxslt lib32-libxslt libva lib32-libva gtk3 lib32-gtk3 gst-plugins-base-libs lib32-gst-plugins-base-libs vulkan-icd-loader lib32-vulkan-icd-loader "
    PACKAGES+="wine-gecko wine-mono lib32-nvidia-utils moonlight-qt "
    # GreenWithEnvy - nvidia stats - https://www.flathub.org/apps/details/com.leinardi.gwe
    PACKAGES+="gwe "
    # Steam video decoding - https://wiki.archlinux.org/title/Hardware_video_acceleration
    yay -S nvidia-utils nvidia-vaapi-driver libvdpau-va-gl vdpauinfo libva-utils
    vainfo

    # optional productivity apps
    #PACKAGES+="zoom slack-desktop dropbox dropbox-cli maestral maestral-qt sparsebundlefs "

    # KVM thin provisioning tools, virt-sparsify - https://www.certdepot.net/kvm-thin-provisioning-tip/
    # TODO SINCE BROKEN: PACKAGES+="guestfs-tools "
    # TODO possibly virtio-win qemu-guest-agent needed for auto suspend
else
    # https://flatpak.org/setup/Ubuntu/
    PACKAGES+="flatpak gnome-software-plugin-flatpak "
    PACKAGES+="systat python3-pip openssh-server "
    PACKAGES+="nvidia-driver-470 nvidia-utils-470 "
    # KVM thin provisioning tools, virt-sparsify - https://www.certdepot.net/kvm-thin-provisioning-tip/
    PACKAGES+="libguestfs-tools "
    # Setup libvirt for Single GPU Passhthrough - https://gitlab.com/risingprismtv/single-gpu-passthrough/-/wikis/4)-Configuring-of-Libvirt
    PACKAGES+="qemu-kvm libvirt-clients libvirt-daemon-system bridge-utils virt-manager ovmf driverctl "
    #TODO: protonup protonup-qt 
fi

# TODO: remove xserver-xorg-video-nouveau

# https://cockpit-project.org/running.html#ubuntu
PACKAGES+="cockpit cockpit-machines cockpit-pcp nvtop packagekit gnome-packagekit "

echo
echo "Running: ${PACKAGE_MANAGER_BIN} ${PACKAGE_MANAGER_INSTALL_CMD} ${PACKAGES}"
echo
${PACKAGE_MANAGER_BIN} ${PACKAGE_MANAGER_INSTALL_CMD} ${PACKAGES}

#sudo apt install -y $PACKAGES

#TODO: set default virsh connection: https://rabexc.org/posts/libvirt-default-url

if  [ "${OS_ID_LIKE}" = "arch" ]; then
    echo "Additional steps for arch"
    sudo systemctl start bluetooth
    sudo systemctl enable bluetooth

    # setup SSL cert for Barrier : https://github.com/debauchee/barrier/issues/231#issuecomment-963408739
    mkdir -p ~/.local/share/barrier/SSL/Fingerprints
    openssl req -x509 -nodes -days 365 -subj /CN=Barrier -newkey rsa:4096 -keyout ~/.local/share/barrier/SSL/Barrier.pem -out ~/.local/share/barrier/SSL/Barrier.pem
    openssl x509 -fingerprint -sha1 -noout -in ~/.local/share/barrier/SSL/Barrier.pem > ~/.local/share/barrier/SSL/Fingerprints/Local.txt
else
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

fi

flatpak install -y com.mattjakeman.ExtensionManager
flatpak install -y net.cozic.joplin_desktop

exit 0

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
    sudo ${UPDATE_GRUB_CMD}
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

echo
echo "updating libvirt: cp ${LIBVIRT_CFG_PATH} ${BACKUP_PATH}/libvirtd.conf_$(date +%Y%m%d_%H%M%S)"
echo

cp ${LIBVIRT_CFG_PATH} "${BACKUP_PATH}/libvirtd.conf_$(date +%Y%m%d_%H%M%S)"

uncommmentLineFromFile 'unix_sock_group = "libvirt"' "$LIBVIRT_CFG_PATH"
uncommmentLineFromFile 'unix_sock_rw_perms = "0770"' "$LIBVIRT_CFG_PATH"

appendLineToFile 'log_filters="1:qemu"' "$LIBVIRT_CFG_PATH"
appendLineToFile 'log_outputs="1:file:/var/log/libvirt/libvirtd.log"' "$LIBVIRT_CFG_PATH"

sudo usermod -a -G libvirt $(whoami)
sudo systemctl start libvirtd
sudo systemctl enable libvirtd

echo
diff ${LIBVIRT_CFG_PATH} "${BACKUP_PATH}/libvirtd.conf_$(date +%Y%m%d_%H%M%S)"
echo

echo
echo "updating qemu conf: ${QEMU_CFG_PATH} ${BACKUP_PATH}/qemu.conf_$(date +%Y%m%d_%H%M%S)"
echo

sudo cp ${QEMU_CFG_PATH} "${BACKUP_PATH}/qemu.conf_$(date +%Y%m%d_%H%M%S)"
replaceLineInFile '#user = "root"' "user = '$(whoami)'" "$QEMU_CFG_PATH"
replaceLineInFile '#group = "root"' "group = '$(whoami)'" "$QEMU_CFG_PATH"

echo "restarting libvirtd"
sudo systemctl restart libvirtd
sudo usermod -a -G kvm,libvirt $(whoami)

echo
diff ${QEMU_CFG_PATH} "${BACKUP_PATH}/qemu.conf_$(date +%Y%m%d_%H%M%S)"
echo

# automatically start virsh network on boot
sudo virsh net-autostart default

# Step 7: https://gitlab.com/risingprismtv/single-gpu-passthrough/-/wikis/6)-Preparation-and-placing-of-ROM-file

echo "setting up vgabios rom"
sudo mkdir /usr/share/vgabios
sudo wget https://raw.githubusercontent.com/matt22207/autotux/main/TU104.rom -O /usr/share/vgabios/TU104.rom
sudo chmod -R 660 /usr/share/vgabios/TU104.rom
sudo chown $(whoami):$(whoami) /usr/share/vgabios/TU104.rom

### TODO ###

# Hibernating a VM with devices passed through
# https://www.reddit.com/r/VFIO/comments/erys86/hibernating_a_vm_with_devices_passed_through/ff7a2he/?context=3
# https://www.reddit.com/r/VFIO/comments/5hi4ce/pci_passthrough_suspending_a_vm_starting_a_new_vm/
# Add <suspend-to-disk enabled='yes'/> to the <pm> section of your VM XML.
# ---  <pm> <suspend-to-mem enabled='yes'/> <suspend-to-disk enabled='yes'/> </pm> 
# Enable hibernation in your guest with powercfg.exe /hibernate on in the Windows command prompt.
# To hibernate from the host you need to install the qemu guest agent in Windows.
# --- https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/6/html/virtualization_administration_guide/sect-qemu_guest_agent-running_the_qemu_guest_agent_on_a_windows_guest
# add a qemu-ga "channel" to your VM
# systemd hooks for automatically hibernating guest when suspend/shutdown host
# --- Auto suspend and resume KVM Virtual Machine with the host: 
# --- https://abishekmuthian.com/auto-suspend-and-resume-kvm-virtual-machine-with-the-host/
# --- on shutdown: https://unix.stackexchange.com/questions/39226/how-to-run-a-script-with-systemd-right-before-shutdown
# --- detect status: https://stackoverflow.com/questions/37453525/how-can-i-check-specific-server-running-or-notusing-virsh-commands-before-i-s
# virsh dompmsuspend win10 disk

# vi /usr/lib/systemd/system-sleep/vm

#!/bin/sh
# 
# case "$1" in
#     pre)
#         VM=win10
#         echo "`date` : checking virsh status for suspend"
#         tmp=$(virsh list --all | grep " $VM " | awk '{ print $3}')
#         if ([ "x$tmp" == "x" ] || [ "x$tmp" != "xrunning" ])
#         then
#                 echo "VM does not exist or is shut down!"
#                 # Try additional commands here...
#         else
#                 echo "`date` : VM is running! starting suspend"
#                 virsh dompmsuspend win10 disk

#                 state=$(virsh list --all | grep " $VM " | awk '{ print $3}')
#                 while ([ "x$state" != "xshut" ]); do
#                         sleep 0.1
#                         state=$(virsh list --all | grep " $VM " | awk '{ print $3}')
#                         echo "`date` : sleep : ${state}"
#                 done;
#                 sleep 1
#                 echo "`date` : vm shutdown complete - ready for HW suspend"
#         fi
#         ;;
# esac
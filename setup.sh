#!/bin/bash

# wget -O - https://raw.githubusercontent.com/matt22207/autotux/main/setup.sh | bash

# https://itsfoss.com/fedora-dark-mode/
gsettings set org.gnome.desktop.interface gtk-theme Adwaita-dark
gsettings set org.gnome.desktop.interface gtk-theme Yaru-dark

sudo apt update -y && sudo apt upgrade -y
#sudo apt full-upgrade

sudo apt install -y gnome-tweaks neofetch git openssh-server net-tools htop timeshift

# KVM thin provisioning tools, virt-sparsify - https://www.certdepot.net/kvm-thin-provisioning-tip/
sudo apt install -y libguestfs-tools

# https://cockpit-project.org/running.html#ubuntu
sudo apt install -y cockpit cockpit-machines cockpit-pcp

# https://flatpak.org/setup/Ubuntu/
sudo apt install -y flatpak 
sudo apt install -y gnome-software-plugin-flatpak
      
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

sudo flatpak install flathub org.gnome.Extensions

# Setup libvirt for Single GPU Passhthrough - https://gitlab.com/risingprismtv/single-gpu-passthrough/-/wikis/4)-Configuring-of-Libvirt
sudo apt install -y qemu-kvm libvirt-clients libvirt-daemon-system bridge-utils virt-manager ovmf

# latest barrier is in snap. doesn't support Wayland yet
sudo snap install barrier

## PAUSE HERE TO REBOOT

# TODO : Grub font size
# https://vietlq.github.io/2019/09/22/make-grub-font-size-bigger/

#!/bin/bash

# wget -O - https://raw.githubusercontent.com/matt22207/autotux/main/setup.sh | bash

sudo apt update
sudo apt upgrade
sudo apt full-upgrade

sudo apt install gnome-tweaks neofetch git openssh-server net-tools htop 

# KVM thin provisioning tools, virt-sparsify - https://www.certdepot.net/kvm-thin-provisioning-tip/
sudo apt install libguestfs-tools

# https://cockpit-project.org/running.html#ubuntu
sudo apt install cockpit cockpit-machines cockpit-pcp

# https://flatpak.org/setup/Ubuntu/
sudo apt install flatpak 
sudo apt install gnome-software-plugin-flatpak
      
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

sudo flatpak install flathub org.gnome.Extensions

# latest barrier is in snap. doesn't support Wayland yet
sudo snap install barrier

## PAUSE HERE TO REBOOT

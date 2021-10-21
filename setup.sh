#!/bin/bash

# wget -O - https://raw.githubusercontent.com/matt22207/autotux/main/setup.sh | bash

sudo apt update
sudo apt upgrade
sudo apt full-upgrade

sudo apt install gnome-tweaks neofetch barrier

# https://flatpak.org/setup/Ubuntu/
sudo apt install flatpak 
sudo apt install gnome-software-plugin-flatpak
      
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

flatpak install flathub org.gnome.Extensions

## PAUSE HERE TO REBOOT

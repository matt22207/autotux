#!/bin/bash

# initial setup script for proxmox server.. to install this script from github, run:
#
# apt update && apt install git
# git clone https://github.com/matt22207/autotux.git
# cd autotux
# chmod +x setup_proxmox.sh
# bash ./setup_proxmox.sh

source ./config.sh

echo $OS_NAME
exit 0
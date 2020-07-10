#!/bin/bash
# Basic Arch Linux installation script to deploy configure X.org and deploy the Plasma Desktop Environment.

# Stop execution if any errors occur
set -e -u

deploy_xorg () {
    pacman --sync --refresh --needed --noconfirm xorg-server
}
deploy_xorg

deploy_proprietary_drivers () {
    pacman --sync --refresh --needed --noconfirm xf86-video-intel vulkan-intel
}
deploy_proprietary_drivers

deploy_plasma () {
    pacman --sync --refresh --needed --noconfirm plasma-meta qt5-virtualkeyboard dolphin konsole
}
deploy_plasma

configure_sddm () {
    mkdir -p /etc/sddm.conf.d
    printf '%s\n' > /etc/sddm.conf.d/uid.conf \
    '[Users]' \
    'MaximumUid=113832' \
    'MinimumUid=113832'
}
configure_sddm

enable_sddm () {
    systemctl enable sddm
}
enable_sddm
 
systemctl reboot

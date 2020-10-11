#!/bin/bash
# Basic Arch Linux installation script to install and configure X.org, and install the Plasma Desktop Environment

set -e -u
source files/vars

deploy_xorg () {
    pacman --sync --refresh --needed --noconfirm xorg-server
}
deploy_xorg

install_drivers () {
    pacman --sync --refresh --needed --noconfirm xf86-video-intel vulkan-intel
}
install_drivers

deploy_plasma () {
    pacman --sync --refresh --needed --noconfirm plasma-meta qt5-virtualkeyboard packagekit-qt5 dolphin konsole
}
deploy_plasma

configure_sddm () {
    mkdir -p /etc/sddm.conf.d
    printf '%s\n' > /etc/sddm.conf.d/uid.conf \
        "[Users]" \
        "MaximumUid=$user_id" \
        "MinimumUid=$user_id"
}
configure_sddm

enable_sddm () {
    systemctl enable sddm
}
enable_sddm

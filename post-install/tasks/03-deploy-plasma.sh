#!/bin/bash
# Basic Arch Linux installation script to install and configure X.org, and install the Plasma Desktop Environment

set -e -u
source files/vars

pacman --sync --refresh --needed --noconfirm xorg-server
pacman --sync --refresh --needed --noconfirm xf86-video-intel vulkan-intel
pacman --sync --refresh --needed --noconfirm plasma-meta qt5-virtualkeyboard packagekit-qt5 dolphin konsole

mkdir -p /etc/sddm.conf.d
cat <<EOF > /etc/sddm.conf.d/kde_settings.conf
[Autologin]
Relogin=false
Session=plasma
User=$user_name

[General]
HaltCommand=/usr/bin/systemctl poweroff
RebootCommand=/usr/bin/systemctl reboot

[Theme]
Current=breeze

[Users]
MaximumUid=$user_id
MinimumUid=$user_id
EOF

systemctl enable sddm

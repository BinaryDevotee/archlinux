#!/bin/bash

set -e -u
source ../files/parameters


## task 01: network setup
echo 'Enabling DHCP on all ethernet devices'
cat ../files/network-settings/20-ethernet.network > /etc/systemd/network/20-ethernet.network
sleep 1

echo 'Enabling DHCP on all wireless devices'
cat ../files/network-settings/20-wireless.network > /etc/systemd/network/20-wireless.network
sleep 1

echo 'Adding iwd as NetworkManager backend'
cat ../files/network-settings/nm-wifi-backend.conf > /etc/NetworkManager/conf.d/wifi_backend.conf
sleep 1

echo 'Selecting systemd-resolved as the DNS manager'
mkdir -p /etc/iwd
cat ../files/network-settings/iwd-main.conf > /etc/iwd/main.conf
sleep 1

echo 'Activating network services'
systemctl enable --now systemd-networkd systemd-resolved NetworkManager iwd > /dev/null 2>&1
sleep 1

echo "" && echo "Please, connect to continue" && echo "" &&
iwctl station wlan0 get-networks && echo "" &&
read -p "Type the SSID to connect: " ssid
nmcli device wifi connect $ssid --ask


## task 02: system setup
echo 'Creating and configuring user'
systemctl enable --now systemd-homed > /dev/null 2>&1
homectl create $user_name --uid $user_id --member-of=wheel
usermod -a -G wheel $user_name
echo "$user_name ALL=(ALL) ALL" > /etc/sudoers.d/$user_name
sleep 1

echo 'Setting hostname and NTP settings'
hostnamectl set-hostname $host_name
timedatectl set-timezone Europe/Prague
timedatectl set-ntp true
sleep 1

echo 'Adjusting locale settings'
sed -e 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' -i /etc/locale.gen
locale-gen
localectl set-locale en_US.UTF-8
sleep 1

echo 'Creating directories for NFS mounts'
mkdir -p /data/Documents
mkdir -p /data/Music
mkdir -p /data/Pictures
mkdir -p /data/Videos
mkdir -p /data/Work
chown -R $user_name:$user_name /data
sleep 1


## task 03: xorg configuration and plasma deployment
pacman --sync --refresh --needed --noconfirm xorg-server
pacman --sync --refresh --needed --noconfirm xf86-video-intel vulkan-intel
pacman --sync --refresh --needed --noconfirm plasma-meta qt5-virtualkeyboard packagekit-qt5 dolphin konsole kcalc

echo 'Configuring SDDM'
mkdir -p /etc/sddm.conf.d
cat ../files/sddm/kde_settings.conf > /etc/sddm.conf.d/kde_settings.conf
systemctl enable sddm > /dev/null 2>&1
sleep 1


## task 04: system configuration
echo 'Installing additional packages'
pacman --sync --refresh --needed --noconfirm $pkg_list
sleep 1

echo 'Configuring Z-shell'
homectl activate $user_name
wget -q -O /home/$user_name/.zshrc       https://git.grml.org/f/grml-etc-core/etc/zsh/zshrc
wget -q -O /home/$user_name/.zshrc.local https://git.grml.org/f/grml-etc-core/etc/skel/.zshrc
chown $user_name:$user_name /home/$user_name/.zshrc
chown $user_name:$user_name /home/$user_name/.zshrc.local
homectl update $user_name --shell=/usr/bin/zsh --real-name=$real_name --email-address=$email_address --location=$location
cat ../files/misc/alias >> /home/$user_name/.zshrc.local
homectl deactivate $user_name
sleep 1

echo 'Installing Starship'
wget -q -O /tmp/starship-latest.tar.gz https://github.com/starship/starship/releases/latest/download/starship-x86_64-unknown-linux-gnu.tar.gz
tar -xf /tmp/starship-latest.tar.gz -C /usr/local/bin/
rm /tmp/starship-latest.tar.gz
sleep 1

echo 'Configuring firewall'
systemctl enable ufw > /dev/null 2>&1
ufw enable
ufw allow nfs
sleep 1

echo 'Enabling bluetooth'
systemctl enable bluetooth > /dev/null 2>&1
sleep 1

echo 'Post install tasks complete. System will be rebooted.'
sleep 3
systemctl reboot

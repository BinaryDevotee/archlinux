#!/bin/bash

set -e -u
source ../files/parameters


# task 01: customize mkinitcpio
echo 'Generating custom mkinitcpio files'
cat ../files/system/mkinitcpio/mkinitcpio-linux.conf > /etc/mkinitcpio-linux.conf
cat ../files/system/mkinitcpio/mkinitcpio-linux-lts.conf > /etc/mkinitcpio-linux-lts.conf
cat ../files/system/mkinitcpio/presets/linux.preset > /etc/mkinitcpio.d/linux.preset
cat ../files/system/mkinitcpio/presets/linux-lts.preset > /etc/mkinitcpio.d/linux-lts.preset
sleep 1


## task 02: network setup
echo 'Enabling DHCP on all ethernet devices'
cat ../files/system/network-settings/20-ethernet.network > /etc/systemd/network/20-ethernet.network
sleep 1

echo 'Enabling DHCP on all wireless devices'
cat ../files/system/network-settings/20-wireless.network > /etc/systemd/network/20-wireless.network
sleep 1

echo 'Adding iwd as NetworkManager backend'
cat ../files/system/network-settings/nm-wifi-backend.conf > /etc/NetworkManager/conf.d/wifi_backend.conf
sleep 1

echo 'Selecting systemd-resolved as the DNS manager'
mkdir -p /etc/iwd
cat ../files/system/network-settings/iwd-main.conf > /etc/iwd/main.conf
sleep 1

echo 'Activating network services'
systemctl enable --now systemd-networkd systemd-resolved > /dev/null 2>&1
systemctl enable --now iwd NetworkManager > /dev/null 2>&1
sleep 8

echo "" && echo "Please, connect to continue" && echo "" &&
iwctl station wlan0 get-networks && echo "" &&
read -p "Type the SSID to connect: " ssid
nmcli device wifi connect $ssid --ask


## task 03: system setup
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
hwclock --systohc
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


## task 04: system tuning
echo 'Installing packages packages for system tuning'
pacman --sync --refresh --needed --noconfirm $pkg_hardware
sleep 1

echo 'Setting healthy battery thresholds'
tlp setcharge 85 90 BAT0
tlp setcharge 85 90 BAT1
sleep 1

echo 'Configuring systemd services for system tuning'
systemctl mask systemd-rfkill.service > /dev/null 2>&1
systemctl mask systemd-rfkill.socket > /dev/null 2>&1
systemctl enable tlp.service > /dev/null 2>&1
sleep 1


## task 05: xorg configuration and plasma deployment
pacman --sync --refresh --needed --noconfirm xorg-server
pacman --sync --refresh --needed --noconfirm xf86-video-intel vulkan-intel
pacman --sync --refresh --needed --noconfirm plasma-meta
pacman --sync --refresh --needed --noconfirm qt5-virtualkeyboard packagekit-qt5 dolphin konsole kcalc kate spectacle kdialog

echo 'Configuring SDDM'
mkdir -p /etc/sddm.conf.d
cat ../files/apps/sddm/kde_settings.conf > /etc/sddm.conf.d/kde_settings.conf
sed -i "s/max-user-id/$user_id/g" /etc/sddm.conf.d/kde_settings.conf
sed -i "s/min-user-id/$user_id/g" /etc/sddm.conf.d/kde_settings.conf
systemctl enable sddm > /dev/null 2>&1
sleep 1


## task 06: system configuration
echo 'Installing additional packages'
pacman --sync --refresh --needed --noconfirm $pkg_utils
pacman --sync --refresh --needed --noconfirm $pkg_multimedia
pacman --sync --refresh --needed --noconfirm $pkg_apps
sleep 1

echo 'Updating user information'
homectl activate $user_name
homectl update $user_name --shell='/usr/bin/zsh'
homectl update $user_name --real-name="$real_name"
homectl update $user_name --email-address="$email_address"
homectl update $user_name --location="$location"
sleep 1

echo 'Configuring firewall'
systemctl enable ufw > /dev/null 2>&1
ufw enable > /dev/null 2>&1
ufw allow nfs > /dev/null 2>&1
sleep 1

echo 'Enabling bluetooth'
systemctl enable bluetooth > /dev/null 2>&1
sleep 1

echo 'Disabling the root user'
passwd --delete root > /dev/null 2>&1
passwd --lock root > /dev/null 2>&1
sleep 1


## task 07: apps configuration
echo 'Installing Starship'
wget -q -O /tmp/starship-latest.tar.gz -i ../files/apps/starship/download_url
tar -xf /tmp/starship-latest.tar.gz -C /usr/local/bin/
rm /tmp/starship-latest.tar.gz
sleep 1

echo 'Configuring Z-shell'
cat ../files/apps/zsh/zshrc > $user_home/.zshrc
cat ../files/apps/zsh/zshrc.local > $user_home/.zshrc.local
cat ../files/apps/zsh/aliases >> $user_home/.zshrc.local
sleep 1

echo 'Configuring tmux'
cat ../files/apps/tmux/tmux.conf > $user_home/.tmux.conf
sleep 1

echo 'Configuring mpv'
mkdir -p $user_home/.config/mpv
cat ../files/apps/mpv/mpv.conf > $user_home/.config/mpv/mpv.conf
sleep 1

echo 'Configuring nvim'
mkdir -p $user_home/.config/nvim
cat ../files/apps/nvim/init.vim > $user_home/.config/nvim/init.vim
sleep 1

echo 'Adjusting file permissions'
chown -R $user_name:$user_name $user_home
homectl deactivate $user_name
sleep 1

echo 'Post install tasks complete. System will be rebooted.'
sleep 3
systemctl reboot

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


## task02: configuring network
echo 'Configuring systemd networking'
cat ../files/system/network/systemd/20-ethernet.network > /etc/systemd/network/20-ethernet.network
cat ../files/system/network/systemd/20-wireless.network > /etc/systemd/network/20-wireless.network
sleep 1

echo 'Configuring NetworkManager'
cat ../files/system/network/NetworkManager/dhcp-client.conf > /etc/NetworkManager/conf.d/dhcp-client.conf
cat ../files/system/network/NetworkManager/dns.conf > /etc/NetworkManager/conf.d/dns.conf
cat ../files/system/network/NetworkManager/rc-manager.conf > /etc/NetworkManager/conf.d/rc-manager.conf
cat ../files/system/network/NetworkManager/systemd-resolved.conf > /etc/NetworkManager/conf.d/systemd-resolved.conf
cat ../files/system/network/NetworkManager/wifi-backend.conf > /etc/NetworkManager/conf.d/wifi-backend.conf
sleep 1

echo 'Setting default DNS resolver'
mkdir -p /etc/iwd && cat ../files/system/network/iwd/main.conf > /etc/iwd/main.conf
sleep 1

echo 'Activating network services'
systemctl enable --now systemd-resolved > /dev/null 2>&1
systemctl enable --now iwd > /dev/null 2>&1
systemctl enable --now NetworkManager > /dev/null 2>&1
sleep 1

echo 'Linking resolv.conf to the DNS resolver'
rm /etc/resolv.conf
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
sleep 1

echo "" && echo "Connecting to WiFi..." && echo "" &&
while ! nmcli device wifi connect $ssid_name password $ssid_pass ; do sleep 2 ; done

echo 'Installing resolvconf binary'
pacman -Syu --needed --noconfirm systemd-resolvconf > /dev/null 2>&1
sleep 1


## task 03: system setup
echo 'Creating and configuring user'
groupadd $group_name -g $user_id
useradd $user_name -u $user_id -g $group_name -m -s /usr/bin/zsh > /dev/null 2>&1
echo 'atrodrig:default' | chpasswd
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
locale-gen > /dev/null 2>&1
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
pacman -Syu --needed --noconfirm $pkg_hardware
sleep 1

echo 'Setting healthy battery thresholds'
cat ../files/system/battery/01-battery-thresholds.conf > /etc/tlp.d/01-battery-thresholds.conf
sleep 1

echo 'Configuring systemd services for system tuning'
systemctl mask systemd-rfkill.service > /dev/null 2>&1
systemctl mask systemd-rfkill.socket > /dev/null 2>&1
systemctl enable tlp.service > /dev/null 2>&1
sleep 1


## task 05: xorg, video drivers, and desktop environment installation and configuration
pacman -Syu --needed --noconfirm xorg-server
pacman -Syu --needed --noconfirm xf86-video-intel vulkan-intel
pacman -Syu --needed --noconfirm $pkg_de
pacman -Syu --needed --noconfirm $pkg_de_addons

echo 'Configuring SDDM'
mkdir -p /etc/sddm.conf.d
cat ../files/apps/sddm/kde_settings.conf > /etc/sddm.conf.d/kde_settings.conf
sed -i "s/max-user-id/$user_id/g" /etc/sddm.conf.d/kde_settings.conf
sed -i "s/min-user-id/$user_id/g" /etc/sddm.conf.d/kde_settings.conf
systemctl enable sddm > /dev/null 2>&1
sleep 1


## task 06: system configuration
echo 'Installing additional packages'
pacman -Syu --needed --noconfirm $pkg_sys_utils
sleep 1

echo 'Configuring firewall'
systemctl enable --now firewalld > /dev/null 2>&1
firewall-cmd --add-service=nfs --permanent > /dev/null 2>&1
firewall-cmd --reload > /dev/null 2>&1
sleep 1

echo 'Disabling the root user'
passwd --delete root > /dev/null 2>&1
passwd --lock root > /dev/null 2>&1
sleep 1


## task 07: Setting up user space
echo 'Installing additional packages'
pacman -Syu --needed --noconfirm $pkg_usr_utils
pacman -Syu --needed --noconfirm $pkg_multimedia
pacman -Syu --needed --noconfirm $pkg_apps
sleep 1

echo 'Enabling bluetooth'
systemctl enable bluetooth > /dev/null 2>&1
sleep 1

echo 'Installing Starship'
wget -q -O /tmp/starship-latest.tar.gz -i ../files/apps/starship/download_url
tar -xf /tmp/starship-latest.tar.gz -C /usr/local/bin/
rm /tmp/starship-latest.tar.gz
sleep 1

echo 'Configuring additional packages [zsh, tmux, mpv, nvim]'
# zsh
cat ../files/apps/zsh/zshrc > $user_home/.zshrc
cat ../files/apps/zsh/zshrc.local > $user_home/.zshrc.local
cat ../files/apps/zsh/aliases >> $user_home/.zshrc.local

# tmux
cat ../files/apps/tmux/tmux.conf > $user_home/.tmux.conf

# mpv
mkdir -p $user_home/.config/mpv
cat ../files/apps/mpv/mpv.conf > $user_home/.config/mpv/mpv.conf

# nvim
mkdir -p $user_home/.config/nvim
cat ../files/apps/nvim/init.vim > $user_home/.config/nvim/init.vim

echo 'Adjusting file permissions'
chown -R $user_name:$user_name $user_home
sleep 1

echo 'Post install tasks complete. System will be rebooted.'
sleep 3
systemctl reboot

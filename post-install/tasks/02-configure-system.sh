#!/bin/bash

set -e -u
source files/vars

echo 'Creating and configuring user'
systemctl enable --now systemd-homed
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

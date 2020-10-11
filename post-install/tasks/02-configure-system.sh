#!/bin/bash

set -e -u
source files/vars

systemctl enable --now systemd-homed
homectl create $user_name --uid $user_id --member-of=wheel
usermod -a -G wheel $user_name

hostnamectl set-hostname $host_name
timedatectl set-timezone Europe/Prague
timedatectl set-ntp true

sed -e 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' -i /etc/locale.gen
locale-gen
localectl set-locale en_US.UTF-8

mkdir -p /data/Documents
mkdir -p /data/Music
mkdir -p /data/Pictures
mkdir -p /data/Videos
mkdir -p /data/Work

chown -R $user_name:$user_name /data

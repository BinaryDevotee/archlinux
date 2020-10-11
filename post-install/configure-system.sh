#!/bin/bash
# Arch Linux basic system configuration script

set -e -u
source files/vars

add_user () {
#   groupadd -g $user_id $group_name
#   useradd -m -u $user_id $user_name -g $group_name
#   passwd $user_name
    homectl create $user_name --uid $user_id --member-of=wheel
}
echo 'Creating and configuring user'
add_user

#config_user_privileges () {
#    echo '%wheel ALL=(ALL) ALL' > /etc/sudoers.d/$user_name
#    usermod -a -G wheel $user_name
#}
#echo 'Configuring user privileges'
#config_user_privileges

system_setup () {
    hostnamectl set-hostname $host_name
    timedatectl set-timezone Europe/Prague
    timedatectl set-ntp true
}
echo 'Setting hostname, timezone, and NTP'
system_setup

config_locale () {
    sed -e 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' -i /etc/locale.gen
    locale-gen
    localectl set-locale en_US.UTF-8
}
echo 'Defining locale settings'
config_locale

create_dirs () {
    mkdir -p /data/Documents
    mkdir -p /data/Music
    mkdir -p /data/Pictures
    mkdir -p /data/Videos

    chown -R $user_name:$user_name /data
}
create_dirs

systemctl reboot

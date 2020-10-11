#!/bin/bash

set -e -u

echo 'Enabling DHCP on all wired interfaces'
cat <<EOF > /etc/systemd/network/20-wired.network
[Match]
Name=enp*

[Network]
DHCP=yes
EOF
sleep 1

echo 'Enabling DHCP on all wireless interfaces'
cat <<EOF > /etc/systemd/network/25-wireless.network
[Match]
Name=wlan*

[Network]
DHCP=yes
EOF
sleep 1

echo 'Adding iwd as NetworkManager backend'
cat <<EOF > /etc/NetworkManager/conf.d/wifi_backend.conf
[device]
wifi.backend=iwd
EOF
sleep 1

mkdir -p /etc/iwd

echo 'Selecting systemd-resolved as the DNS manager'
cat <<EOF > /etc/iwd/main.conf
[Network]
NameResolvingService=systemd
EOF
sleep 1

echo 'Activating network services'
systemctl enable --now systemd-networkd systemd-resolved NetworkManager iwd > /dev/null 2>&1
sleep 1

echo "Please, connect to continue" && echo "" &&
iwctl station wlan0 scan &&
iwctl station wlan0 get-networks && echo ""
read -p "Type the SSID to connect: " ssid
nmcli device wifi connect $ssid --ask

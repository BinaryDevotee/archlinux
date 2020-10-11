#!/bin/bash
# Arch Linux basic network configuration script

set -e -u

dhcp_wired_config () {
    printf '%s\n' > /etc/systemd/network/20-wired.network \
    '[Match]' \
    'Name=enp*' \
    '' \
    '[Network]' \
    'DHCP=yes'
}
dhcp_wired_config

dhcp_wireless_config () {
    printf '%s\n' > /etc/systemd/network/25-wireless.network \
    '[Match]' \
    'Name=wlan*' \
    '' \
    '[Network]' \
    'DHCP=yes'
}
dhcp_wireless_config

nm_iw () {
    printf '%s\n' > /etc/NetworkManager/conf.d/wifi_backend.conf \
    '[device]' \
    'wifi.backend=iwd'
}
nm_iw

set_dns_mgr () {
    mkdir -p /etc/iwd
    printf '%s\n' > /etc/iwd/main.conf \
    '[Network]' \
    'NameResolvingService=systemd'
}
set_dns_mgr

enable_net_services () {
    systemctl enable --now systemd-networkd \
        systemd-resolved \
        NetworkManager \
        iwd
}
enable_net_services

wifi_connect () {
    echo "Available Wireless networks:" && echo "" && nmcli device wifi && echo ""
    read -p "Type the SSID to connect: " ssid
    nmcli device wifi connect $ssid --ask
}
wifi_connect

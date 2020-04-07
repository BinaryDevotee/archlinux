#!/bin/bash
# This script installs and configures libvirt packages (KVM+QEMU) to enable this host to act as a hypervisor

set -e -u

install_pkgs () {

    # This function installs the required packages for libvirt KVM+QEMU to work.
    # Packages 'ebtables', 'dnsmasq', 'bridge-utils', and 'openbsd-netcat' are necessary for remote administration.
    # Packages 'demidecode' is required by libvirt.
    # Install the package 'virt-install' to manage libvirt using the GUI.

    user_name=

    pacman -Sy --needed --noconfirm libvirt \
        qemu \

    usermod -a -G libvirt $user_name
    systemctl enable --now libvirtd

}
echo 'Installing the required packages'

configure_kvm_pools () {

    img_path=
    iso_path=

    # This function creates the additional storage pools that we will use in this host.
    # Please, note that the 'default' pool is left untouched as libvirt will throw errors if we change the path
    # upon launching virt-manager or restarting libvirtd service.

    # Create the storage pools definition
    virsh pool-define-as --name images --type dir --target $img_path
    virsh pool-define-as --name iso --type dir --target $iso_path

    # Create the local directories
    virsh pool-build images
    virsh pool-build iso

    # Start the storage pools
    virsh pool-start images
    virsh pool-start iso

    # Turn on autostart
    virsh pool-autostart images
    virsh pool-autostart iso

}
echo 'Configuring storage pools'

start_default_network () {
    
    # This function enables and starts the default network.
    virsh net-autostart default
    virsh net-start default

}
echo 'Starting and enabling the default network'

install_pkgs
configure_kvm_pools
start_default_network

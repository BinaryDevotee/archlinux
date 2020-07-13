#!/bin/bash
# This script installs and configures libvirt packages (KVM+QEMU) to enable this host to act as a hypervisor

source ../../post-install/files/vars

load_modules () {
    echo 'fuse' > /etc/modules-load.d/fuse.conf
    echo 'options intel_iommu=soft' >> /boot/loader/entries/*.conf
}
load_modules

install_pkgs () {

    # This function installs the required packages for libvirt KVM+QEMU to work.
    # Packages 'ebtables', 'dnsmasq', 'bridge-utils', and 'openbsd-netcat' are necessary for remote administration.
    # Packages 'demidecode' is required by libvirt.
    # Install the package 'virt-install' to manage libvirt using the GUI.

    pacman --sync --refresh --needed --noconfirm libvirt \
    qemu-headless \
    ebtables \
    dnsmasq \
    bridge-utils \
    openbsd-netcat \
    dmidecode \
    virt-install

    usermod -a -G libvirt $user_name
    systemctl enable --now libvirtd

}
install_pkgs

delete_kvm_pools () {

    # Remove the default pool
    virsh pool-destroy default
    virsh pool-undefine default

    # Remove the iso pool
    virsh pool-destroy iso
    virsh pool-undefine iso
}
delete_kvm_pools

create_kvm_pools () {

    img_path=/data/VirtualMachines/images
    iso_path=/data/VirtualMachines/iso

    # This function creates the additional storage pools that we will use in this host.

    # Create the storage pools definition
    virsh pool-define-as --name default --type dir --target $img_path
    virsh pool-define-as --name iso --type dir --target $iso_path

    # Create the local directories
    virsh pool-build default
    virsh pool-build iso

}
create_kvm_pools

start_kvm_pools () {

    # Start the storage pools
    virsh pool-start default
    virsh pool-start iso
 
    # Turn on autostart
    virsh pool-autostart default
    virsh pool-autostart iso

}
start_kvm_pools

start_default_network () {
    
    # This function enables and starts the default network.
    virsh net-autostart default
    virsh net-start default

}
start_default_network

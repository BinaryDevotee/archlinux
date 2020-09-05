#!/bin/bash
# This script installs and configures libvirt packages (KVM+QEMU) to enable this host to act as a hypervisor

source ../../post-install/files/vars

load_modules () {
    echo 'fuse' > /etc/modules-load.d/fuse.conf
    echo 'options intel_iommu=soft' >> /boot/loader/entries/*.conf
}
load_modules

install_pkgs () {
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
    virsh pool-destroy default
    virsh pool-undefine default
}
delete_kvm_pools

create_kvm_pools () {
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
    virsh net-autostart default
    virsh net-start default
}
start_default_network

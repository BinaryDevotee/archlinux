#!/bin/bash
# This script installs and configures libvirt packages (KVM+QEMU) to enable this host to act as a hypervisor

if [ $(whoami) != 'root' ]
  then
    echo "You must be root to do this."
    exit
fi

source ../../post-install/files/vars

load_modules () {
    echo 'fuse' > /etc/modules-load.d/fuse.conf
    echo 'options intel_iommu=on' >> /boot/loader/entries/*.conf
}
load_modules

install_pkgs () {
    pacman --sync --refresh --needed --noconfirm libvirt \
    qemu \
    ebtables \
    dnsmasq \
    bridge-utils \
    openbsd-netcat \
    dmidecode \
    virt-manager
}
install_pkgs

fix_permissions () {
    usermod -a -G libvirt $user_name
    systemctl enable --now libvirtd
}
fix_permissions

delete_kvm_pools () {
    virsh pool-destroy default
    virsh pool-undefine default
}
delete_kvm_pools

create_kvm_pools () {
    # Define default/iso pools
    virsh pool-define-as --name default --type dir --target $img_path
    virsh pool-define-as --name iso --type dir --target $iso_path
    # Build default/iso pools
    virsh pool-build default
    virsh pool-build iso
}
create_kvm_pools

start_kvm_pools () {
    # Start default/iso pools
    virsh pool-start default
    virsh pool-start iso
    # Autostart default/iso pools
    virsh pool-autostart default
    virsh pool-autostart iso
}
start_kvm_pools

start_default_network () {
    virsh net-autostart default
    virsh net-start default
}
start_default_network

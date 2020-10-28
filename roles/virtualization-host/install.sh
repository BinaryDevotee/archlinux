#!/bin/bash
# This script installs and configures libvirt packages (KVM+QEMU) to enable this host to act as a hypervisor

# check if user has 'root' privileges
if [ $(whoami) != 'root' ]
  then
    echo "You must be root to do this."
    exit
fi

# define vars
user_name='atrodrig'
img_path='/data/VirtualMachines/images'
iso_path='/data/VirtualMachines/iso'

# enabling the 'fuse' module
echo 'fuse' > /etc/modules-load.d/fuse.conf

# install required packages
pacman --sync --refresh --needed --noconfirm libvirt \
qemu \
ebtables \
dnsmasq \
bridge-utils \
openbsd-netcat \
dmidecode \
virt-manager

usermod -a -G libvirt $user_name
systemctl enable --now libvirtd

# clean up existing pools
virt_pools=$(virsh pool-list --all |awk 'FNR >= 3 {print $1}')
for i in $virt_pools
do
  virsh pool-destroy --pool $i
  virsh pool-undefine --pool $i
done

# define default/iso pools
virsh pool-define-as --name default --type dir --target $img_path
virsh pool-define-as --name iso --type dir --target $iso_path

# build default/iso pools
virsh pool-build default
virsh pool-build iso

# start default/iso pools
virsh pool-start default
virsh pool-start iso

# autostart default/iso pools
virsh pool-autostart default
virsh pool-autostart iso

# start default network
virsh net-start default
virsh net-autostart default

# restart libvirt service
systemctl restart libvirtd

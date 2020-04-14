#!/bin/bash
# Basic Arch Linux installation script for a virtual machine using BIOS, GPT, and no encryption

# Stop execution if any errors occur
set -e -u 

# Specify here the storage device where Arch Linux will be installed i.e: /dev/sda
pv='/dev/vda'

partition_disk () {

    # This function uses parted to partition the main block disk and set the correct flags
    # It creates two partitions: 1 x 300MiB Boot Partition | 1 x 100% FREE Linux Filesystem

    parted --script $pv \
    mklabel gpt \
    mkpart primary 1MiB 6MiB \
    mkpart primary 6MiB 100% \
    name 1 ARCH_BOOT \
    name 2 ARCH_OS \
    set 1 bios_grub on \
    align-check optimal 1 \
    align-check optimal 2

}
partition_disk

format_partitions () {

    # This function formats, labels, and mounts the required partitions
    # Partition 1: GRUB Partition | Partition 2: XFS - ARCH_OS

    mkfs.xfs -f /dev/disk/by-partlabel/ARCH_OS -L ARCH_OS
    mount --label ARCH_OS /mnt

}
format_partitions

setup_mirrors () {
    mirrorlist='https://www.archlinux.org/mirrorlist/?country=CZ&country=DE'
    curl $mirrorlist -o /etc/pacman.d/mirrorlist
    sed -e 's/#Server/Server/g' -i /etc/pacman.d/mirrorlist
} # Downloading and formatting the latest mirrorlist file Czechia and Germany
setup_mirrors

install_archlinux () {
    pacstrap /mnt base base-devel linux linux-firmware vi vim networkmanager openssh xfsprogs grub
} # Downloading and installing Arch Linux
install_archlinux

generate_fstab () {
    genfstab -L /mnt >> /mnt/etc/fstab
} # Creating the 'fstab' file
generate_fstab

update_initramfs () {
    sed -e '52s/udev/systemd/g' -i /mnt/etc/mkinitcpio.conf 
    arch-chroot /mnt mkinitcpio --allpresets
} # Replacing 'udev' generated initramfs by 'systemd'                                                                 
update_initramfs

root_passwd () {
    arch-chroot /mnt passwd
} # Setting the root password in the chroot environment
root_passwd

configure_grub () {
    arch-chroot /mnt grub-install $pv
    arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
} # Installing and configuring GRUB on /dev/vda
configure_grub

default_services () {
    arch-chroot /mnt systemctl enable NetworkManager sshd
} # Enabling NetworkManager and OpenSSH services
default_services

ps_scripts () {
    cp -r ../../post-install /mnt/root
    cp -r ../../roles /mnt/root
} # Copying additional post-install scripts to /root
ps_scripts

finish_install () {
    umount -R /mnt
    systemctl poweroff
} # Umounting directories and rebooting system
finish_install

#!/bin/bash
# Basic Arch Linux LTS installation script for bare metal UEFI with systemd-boot, GPT, and no encryption

# Stop execution if any errors occur
set -e -u

# Specify here the storage device where Arch Linux will be installed i.e: /dev/sda
echo "" && lsblk && echo ""
read -p "Specify the block device for the installation [i.e: /dev/sda]: " pv

wipe_disk () {
    wipefs --all --force $pv && blkdiscard $pv
} # Wiping and discarding blocks on $pv
wipe_disk
    
partition_disk () {
    
    # This function uses parted to partition the main block disk and set the correct flags
    # It creates three partitions: 1 x 300MiB Boot Partition | 1 x 221GiB Linux Filesystem | 1 x 100% SWAP

    parted --script $pv \
    mklabel gpt \
    mkpart primary 1MiB 301MiB \
    mkpart primary 301MiB 221GiB \
    mkpart primary 221GiB 100% \
    name 1 ARCH_BOOT \
    name 2 ARCH_OS \
    name 3 ARCH_SWAP \
    set 1 boot on \
    align-check optimal 1 \
    align-check optimal 2 \
    align-check optimal 3
    
}
partition_disk
    
format_partitions () {

    # This function formats, labels, and mounts the required partitions
    # Partition 1: FAT32 - ARCH_BOOT | Partition 2: XFS - ARCH_OS | Partition 3: SWAP - ARCH_SWAP

    # Formatting and labeling partitions
    mkfs.fat -F32 /dev/disk/by-partlabel/ARCH_BOOT -n ARCH_BOOT
    mkfs.xfs -f   /dev/disk/by-partlabel/ARCH_OS   -L ARCH_OS
    mkswap        /dev/disk/by-partlabel/ARCH_SWAP -L ARCH_SWAP

    # Mounting partitions
    mount --label ARCH_OS   /mnt && mkdir --parents /mnt/boot
    mount --label ARCH_BOOT /mnt/boot
    swapon -L     ARCH_SWAP

}
format_partitions

setup_mirrors () {
    mirrorlist='https://www.archlinux.org/mirrorlist/?country=CZ&country=DE'
    curl $mirrorlist -o /etc/pacman.d/mirrorlist
    sed -e 's/#Server/Server/g' -i /etc/pacman.d/mirrorlist
} # Downloading and formatting the latest mirrorlist file Czechia and Germany
setup_mirrors

install_archlinux () {
    pacstrap /mnt base base-devel linux-lts linux-firmware intel-ucode vim networkmanager openssh xfsprogs
} # Downloading and installing Arch Linux LTS
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

bootloader () {

    install_bootloader () {
        arch-chroot /mnt bootctl --path=/boot install
    } # Installing systemd-boot
    install_bootloader

    loader_conf () {
        printf '%s\n' > /mnt/boot/loader/loader.conf \
        'default arch-lts' \
        'timeout 3' \
        'console-mode keep' \
        'editor no'
    } # Populating the loader.conf file
    loader_conf

    entries_conf () {
        printf '%s\n' > /mnt/boot/loader/entries/arch-lts.conf \
        'title   Arch Linux LTS' \
        'linux   /vmlinuz-linux-lts' \
        'initrd  /intel-ucode.img' \
        'initrd  /initramfs-linux-lts.img' \
        'options root=LABEL=ARCH_OS rw'
    } # Populating the arch.conf file
    entries_conf

    update_bootloader () {
        arch-chroot /mnt bootctl --path=/boot update
    } # Updating systemd-boot configuration
    update_bootloader

}
bootloader

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
    swapoff -L ARCH_SWAP
    systemctl poweroff
} # Umounting directories and rebooting system
finish_install

#
# profile-03.sh
#

#!/bin/bash
set -e -u

echo "Available block devices:" && echo "" && lsblk && echo ""
read -p "Specify the block device for the installation [i.e: /dev/sda]: " pv

wipe_disk () {
    wipefs --all --force $pv && blkdiscard $pv
}
wipe_disk

partition_disk () {
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
    mkfs.fat -F32 /dev/disk/by-partlabel/ARCH_BOOT -n ARCH_BOOT
    mkfs.xfs -f /dev/disk/by-partlabel/ARCH_OS -L ARCH_OS
    mkswap /dev/disk/by-partlabel/ARCH_SWAP -L ARCH_SWAP
    mount -L ARCH_OS /mnt && mkdir -p /mnt/boot
    mount -L ARCH_BOOT /mnt/boot
    swapon -L ARCH_SWAP
}
format_partitions

install_archlinux () {
    pacstrap /mnt base base-devel linux-lts linux-firmware intel-ucode vim iwd dhcpcd openresolv openssh xfsprogs
}
install_archlinux

generate_fstab () {
    genfstab -L /mnt >> /mnt/etc/fstab
}
generate_fstab

update_initramfs () {
    sed -e '52s/udev/systemd/g' -i /mnt/etc/mkinitcpio.conf
    arch-chroot /mnt mkinitcpio --allpresets
}
update_initramfs

root_passwd () {
    arch-chroot /mnt passwd
}
root_passwd

bootloader () {
    install_bootloader () {
        arch-chroot /mnt bootctl --path=/boot install
    }
    install_bootloader

    loader_conf () {
        printf '%s\n' > /mnt/boot/loader/loader.conf \
        'default arch-lts' \
        'timeout 3' \
        'console-mode keep' \
        'editor no'
    }
    loader_conf

    entries_conf () {
        printf '%s\n' > /mnt/boot/loader/entries/arch-lts.conf \
        'title   Arch Linux LTS' \
        'linux   /vmlinuz-linux-lts' \
        'initrd  /intel-ucode.img' \
        'initrd  /initramfs-linux-lts.img' \
        'options root=LABEL=ARCH_OS rw' \
	'options intel_iommu=soft'
    }
    entries_conf

    update_bootloader () {
        arch-chroot /mnt bootctl --path=/boot update
    }
    update_bootloader
}
bootloader

ps_scripts () {
    cp -r ../post-install /mnt/root
    cp -r ../roles /mnt/root
}
ps_scripts

finish_install () {
    umount -R /mnt
    swapoff -L ARCH_SWAP
    systemctl poweroff
}
finish_install

#
# profile-02.sh
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
    mkpart primary 301MiB 201GiB \
    name 1 ARCH_BOOT \
    name 2 ARCH_OS \
    set 1 boot on \
    align-check optimal 1 \
    align-check optimal 2
}
partition_disk

format_partitions () {
    mkfs.fat -F32 /dev/disk/by-partlabel/ARCH_BOOT -n ARCH_BOOT
    mkfs.xfs -f /dev/disk/by-partlabel/ARCH_OS -L ARCH_OS
    mount -L ARCH_OS /mnt && mkdir -p /mnt/boot
    mount -L ARCH_BOOT /mnt/boot 
}
format_partitions

install_archlinux () {
    pacstrap /mnt base base-devel linux linux-firmware intel-ucode vim iwd dhcpcd openresolv openssh xfsprogs
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
        'default arch' \
        'timeout 3' \
        'console-mode keep' \
        'editor no'
    }
    loader_conf

    entries_conf () {
        printf '%s\n' > /mnt/boot/loader/entries/arch.conf \
        'title   Arch Linux' \
        'linux   /vmlinuz-linux' \
        'initrd  /intel-ucode.img' \
        'initrd  /initramfs-linux.img' \
        'options root=LABEL=ARCH_OS rw' \
	'options intel_iommu=on'
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
    systemctl poweroff
}
finish_install

#
# profile-04.sh
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
    name 2 CRYPT_ROOT \
    set 1 boot on \
    align-check optimal 1 \
    align-check optimal 2
}
partition_disk

encrypt_partitions () {
    mkfs.fat -F32 /dev/disk/by-partlabel/ARCH_BOOT -n ARCH_BOOT
    cryptsetup --verbose --batch-mode --verify-passphrase luksFormat /dev/disk/by-partlabel/CRYPT_ROOT --label CRYPT_ROOT
    cryptsetup luksOpen /dev/disk/by-partlabel/CRYPT_ROOT CRYPT_ROOT
    mkfs.xfs -f /dev/mapper/CRYPT_ROOT -L ARCH_OS
    mount -L ARCH_OS /mnt && mkdir -p /mnt/boot
    mount -L ARCH_BOOT /mnt/boot
}
encrypt_partitions

install_archlinux () {
    pacstrap /mnt base base-devel linux linux-firmware intel-ucode vim networkmanager openssh xfsprogs
}
install_archlinux

generate_fstab () {
    genfstab -L /mnt >> /mnt/etc/fstab
}
generate_fstab

update_initramfs () {
    hooks='base systemd autodetect keyboard modconf block sd-encrypt filesystems fsck'
    sed -e "52s/^.*/HOOKS=($hooks)/g" -i /mnt/etc/mkinitcpio.conf
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
        dm_crypt_uuid="$(blkid /dev/disk/by-partlabel/CRYPT_ROOT --match-tag UUID --output value)"
        printf '%s\n' > /mnt/boot/loader/entries/arch.conf \
        'title   Arch Linux' \
        'linux   /vmlinuz-linux' \
        'initrd  /intel-ucode.img' \
        'initrd  /initramfs-linux.img' \
        'options luks.name='$dm_crypt_uuid'=ARCH_OS root=/dev/mapper/ARCH_OS rw' \
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
    cp -r ../../post-install /mnt/root
    cp -r ../../roles /mnt/root
}
ps_scripts

finish_install () {
    umount -R /mnt
    cryptsetup luksClose CRYPT_ROOT
    systemctl poweroff
}
finish_install

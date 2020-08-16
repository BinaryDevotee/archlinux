#
# profile-05.sh
#

#!/bin/bash
set -e -u 
pv='/dev/vda'

partition_disk () {
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
    mkfs.xfs -f /dev/disk/by-partlabel/ARCH_OS -L ARCH_OS
    mount -L ARCH_OS /mnt
}
format_partitions

install_archlinux () {
    pacstrap /mnt base base-devel linux linux-firmware vim dhcpcd openssh xfsprogs grub
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

configure_grub () {
    arch-chroot /mnt grub-install $pv
    arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
}
configure_grub

default_services () {
    arch-chroot /mnt systemctl enable dhcpcd sshd
}
default_services

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

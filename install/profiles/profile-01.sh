#
# profile-01.sh
#

#!/bin/bash
set -e -u

echo "Available block devices:" && echo "" && lsblk && echo ""
read -p "Specify the block device for the installation [i.e: /dev/sda]: " pv

wipefs -a -f $pv && blkdiscard -f $pv

parted -s $pv \
mklabel gpt \
mkpart primary 1MiB 301MiB \
mkpart primary 301MiB 201GiB \
name 1 ARCH_BOOT \
name 2 ARCH_OS \
set 1 boot on \
align-check optimal 1 \
align-check optimal 2

udevadm settle && sync

mkfs.fat -F32 /dev/disk/by-partlabel/ARCH_BOOT -n ARCH_BOOT
mkfs.f2fs -f /dev/disk/by-partlabel/ARCH_OS -l ARCH_OS
mount -L ARCH_OS /mnt && mkdir -p /mnt/boot
mount -L ARCH_BOOT /mnt/boot 

pacstrap /mnt base base-devel linux linux-firmware intel-ucode neovim networkmanager iwd openssh f2fs-tools
genfstab -L /mnt >> /mnt/etc/fstab

sed -e '52s/udev/systemd/g' -i /mnt/etc/mkinitcpio.conf
arch-chroot /mnt mkinitcpio --allpresets
arch-chroot /mnt passwd

arch-chroot /mnt bootctl --path=/boot install
cat <<EOF > /mnt/boot/loader/loader.conf
default arch
timeout 0
console-mode keep
editor no
EOF

cat <<EOF > /mnt/boot/loader/entries/arch.conf
title   Arch Linux
linux   /vmlinuz-linux
initrd  /intel-ucode.img
initrd  /initramfs-linux.img
options root=LABEL=ARCH_OS rw
options intel_iommu=on
EOF
arch-chroot /mnt bootctl --path=/boot update

cp -r ../post-install /mnt/root
cp -r ../roles /mnt/root

umount -R /mnt
systemctl poweroff

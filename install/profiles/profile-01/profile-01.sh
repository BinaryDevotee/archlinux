#
# profile-01.sh
#

#!/bin/bash
set -e -u

echo "Available block devices:" && echo "" && lsblk && echo "" &&
read -p "Specify the block device for the installation [i.e: /dev/sda]: " pv

wipefs -a -f $pv && blkdiscard -f $pv

parted -s $pv \
mklabel gpt \
mkpart primary 1MiB 301MiB \
mkpart primary 301MiB '85%' \
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

mkdir -p /mnt/etc/mkinitcpio.d
cat profiles/profile-01/files/system/mkinitcpio/mkinitcpio-linux.conf > /mnt/etc/mkinitcpio-linux.conf
cat profiles/profile-01/files/system/mkinitcpio/mkinitcpio-linux-lts.conf > /mnt/etc/mkinitcpio-linux-lts.conf
cat profiles/profile-01/files/system/mkinitcpio/presets/linux.preset > /mnt/etc/mkinitcpio.d/linux.preset
cat profiles/profile-01/files/system/mkinitcpio/presets/linux-lts.preset > /mnt/etc/mkinitcpio.d/linux-lts.preset

pacstrap /mnt base base-devel linux linux-lts linux-firmware intel-ucode vim neovim iwd networkmanager openssh f2fs-tools
genfstab -L /mnt >> /mnt/etc/fstab

# arch-chroot /mnt mkinitcpio --allpresets

arch-chroot /mnt bootctl --path=/boot install
cat profiles/profile-01/files/system/bootloader/loader.conf > /mnt/boot/loader/loader.conf
cat profiles/profile-01/files/system/bootloader/arch.conf > /mnt/boot/loader/entries/arch.conf
cat profiles/profile-01/files/system/bootloader/arch-lts.conf > /mnt/boot/loader/entries/arch-lts.conf
arch-chroot /mnt bootctl --path=/boot update

echo 'root:default' | chpasswd --root /mnt

cp -r profiles/profile-01/post-install /mnt/root
cp -r profiles/profile-01/files /mnt/root
cp -r ../roles /mnt/root

umount -R /mnt
systemctl poweroff

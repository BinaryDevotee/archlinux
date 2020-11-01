#
# profile-04.sh
#

#!/bin/bash
set -e

mkfs.f2fs -f /dev/disk/by-partlabel/ARCH_OS -l ARCH_OS
mount -L ARCH_OS /mnt && mkdir -p /mnt/boot
mount -L BOOT /mnt/boot 
 
pacstrap /mnt base base-devel linux linux-lts linux-firmware intel-ucode vim neovim iwd openssh f2fs-tools
genfstab -L /mnt >> /mnt/etc/fstab
 
arch-chroot /mnt bootctl --path=/boot install
cat profiles/profile-04/files/system/bootloader/loader.conf > /mnt/boot/loader/loader.conf
cat profiles/profile-04/files/system/bootloader/arch.conf > /mnt/boot/loader/entries/arch.conf
cat profiles/profile-04/files/system/bootloader/arch-lts.conf > /mnt/boot/loader/entries/arch-lts.conf
arch-chroot /mnt bootctl --path=/boot update
 
echo 'root:default' | chpasswd --root /mnt
 
cp -r profiles/profile-04/post-install /mnt/root
cp -r profiles/profile-04/files /mnt/root
cp -r ../roles /mnt/root
 
umount -R /mnt
systemctl poweroff

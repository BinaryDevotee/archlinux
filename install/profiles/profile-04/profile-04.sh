#
# profile-04.sh
#

#!/bin/bash
set -e

echo "Available block devices:" && echo "" && lsblk && echo "" &&
read -p "Specify the block device for the installation [i.e: /dev/sda]: " pv

esp="$(sfdisk -l $pv |grep EFI |awk '{print $1}')"
free_space_start="$(parted $pv unit MB print free |grep 'Free Space' |tail -n1 |awk '{print $1}')"
free_space_end="$(parted $pv unit MB print free |grep 'Free Space' |tail -n1 |awk '{print $2}')"
 
parted -s $pv mkpart ARCH_OS $free_space_start $free_space_end
udevadm settle && sync
 
mkfs.f2fs -f /dev/disk/by-partlabel/ARCH_OS -l ARCH_OS
mount -L ARCH_OS /mnt && mkdir -p /mnt/boot
mount $esp /mnt/boot 
 
pacstrap /mnt base base-devel linux linux-firmware intel-ucode vim neovim iwd networkmanager openssh f2fs-tools
genfstab -L /mnt >> /mnt/etc/fstab
 
arch-chroot /mnt bootctl --path=/boot install
cat profiles/profile-04/files/system/bootloader/loader.conf > /mnt/boot/loader/loader.conf
cat profiles/profile-04/files/system/bootloader/arch.conf > /mnt/boot/loader/entries/arch.conf
arch-chroot /mnt bootctl --path=/boot update
 
echo 'root:default' | chpasswd --root /mnt
 
cp -r profiles/profile-04/post-install /mnt/root
cp -r profiles/profile-04/files /mnt/root
cp -r ../roles /mnt/root
 
umount -R /mnt
systemctl poweroff

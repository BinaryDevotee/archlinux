#
# profile-05.sh
#

#!/bin/bash
set -e -u 
pv='/dev/vda'

parted --script $pv \
mklabel gpt \
mkpart ARCH_BOOT 1MiB 6MiB \
mkpart ARCH_OS 6MiB 100% \
set 1 bios_grub on \
align-check optimal 1 \
align-check optimal 2

udevadm settle && sync

mkfs.xfs -f /dev/disk/by-partlabel/ARCH_OS -L ARCH_OS
mount -L ARCH_OS /mnt

pacstrap /mnt base base-devel linux linux-firmware vim networkmanager dhclient openssh xfsprogs grub
genfstab -L /mnt >> /mnt/etc/fstab

arch-chroot /mnt grub-install $pv
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

echo 'root:default' | chpasswd --root /mnt

# WIP: cp -r ../post-install /mnt/root
# WIP: cp -r ../roles /mnt/root

umount -R /mnt
systemctl poweroff

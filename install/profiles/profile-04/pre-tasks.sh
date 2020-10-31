#
# profile-04.sh
# pre-tasks.sh
#

#!/bin/bash
set -e -u

echo "Available block devices:" && echo "" && lsblk && echo "" &&
read -p "Specify the block device for the installation [i.e: /dev/sda]: " pv

wipefs -a -f $pv && blkdiscard -f $pv

parted -s $pv \
mklabel gpt \
\
mkpart BOOT 1MiB 513MiB \
mkpart MSFT_RES 513MiB 545MiB \
mkpart WIN_OS 545MiB 118GiB \
mkpart WIN_DIAG 118GiB 118.5GiB \
mkpart ARCH_OS 118.5GiB 100%FREE \
\
set 1 boot on \
set 1 esp on \
set 2 msftres on \
set 3 msftdata on \
set 4 hidden on \
set 4 diag on \
\
align-check optimal 1 \
align-check optimal 2 \
align-check optimal 3 \
align-check optimal 4 \
align-check optimal 5

udevadm settle && sync

mkfs.fat -F32 /dev/disk/by-partlabel/BOOT     -n BOOT
mkfs.ntfs -f  /dev/disk/by-partlabel/WIN_OS   -L WIN_OS
mkfs.ntfs -f  /dev/disk/by-partlabel/WIN_DIAG -L WIN_DIAG
mkfs.f2fs -f  /dev/disk/by-partlabel/ARCH_OS  -l ARCH_OS

echo 'Proceed to install Windows. The system will be powered off!'
sleep 3
systemctl poweroff

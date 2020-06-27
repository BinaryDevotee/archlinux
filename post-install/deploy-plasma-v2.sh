pacman -Sy --needed --noconfirm xorg-server &&
pacman -Sy --needed --noconfirm plasma-meta qt5-virtualkeyboard dolphin konsole &&
pacman -Sy --needed --noconfirm xf86-video-intel vulkan-intel
sddm --example-config | tee /etc/sddm.conf > /dev/null 2>&1
systemctl reboot

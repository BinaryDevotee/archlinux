pacman -Sy --needed --noconfirm xorg &&
pacman -Sy --needed --noconfirm plasma dolphin konsole &&
sddm --example-config | tee /etc/sddm.conf > /dev/null 2>&1
systemctl reboot

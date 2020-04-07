pacman -Sy --needed --noconfirm xorg xorg-xinit &&
pacman -Sy --needed --noconfirm openbox &&
cp /etc/X11/xinit/xinitrc /home/atrodrig/.xinitrc &&
chown atrodrig:atrodrig /home/atrodrig/.xinitrc &&
systemctl reboot

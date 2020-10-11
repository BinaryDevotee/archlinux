#!/bin/bash
# Basic Arch Linux installation script to install and configure additional packages

set -e -u
source files/vars

pacman --sync --refresh --needed --noconfirm $pkg_list

echo 'Configuring Z-shell'
homectl activate $user_name
wget -q -O /home/$user_name/.zshrc       https://git.grml.org/f/grml-etc-core/etc/zsh/zshrc
wget -q -O /home/$user_name/.zshrc.local https://git.grml.org/f/grml-etc-core/etc/skel/.zshrc
chown $user_name:$user_name /home/$user_name/.zshrc
chown $user_name:$user_name /home/$user_name/.zshrc.local
homectl update $user_name --shell=/usr/bin/zsh
cat files/alias >> /home/$user_name/.zshrc.local
homectl deactivate $user_name

echo 'Installing Starship'
wget -q -O /tmp/starship-latest.tar.gz https://github.com/starship/starship/releases/latest/download/starship-x86_64-unknown-linux-gnu.tar.gz
tar -xf /tmp/starship-latest.tar.gz -C /usr/local/bin/
rm /tmp/starship-latest.tar.gz

echo 'Configuring firewall'
systemctl enable --now ufw
ufw enable
ufw allow nfs


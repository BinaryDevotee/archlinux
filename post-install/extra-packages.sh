#!/bin/bash
# Basic Arch Linux installation script to install and configure additional packages

set -e -u
source files/vars

pkg_install () {
    pacman --sync --refresh --needed --noconfirm $pkg_list
}
echo 'Installing additional packages'
pkg_install

zsh_config () {
    wget -q -O /home/$user_name/.zshrc       https://git.grml.org/f/grml-etc-core/etc/zsh/zshrc
    wget -q -O /home/$user_name/.zshrc.local https://git.grml.org/f/grml-etc-core/etc/skel/.zshrc
    chsh --shell /usr/bin/zsh $user_name
    chown $user_name:$user_name /home/$user_name/.zshrc
    chown $user_name:$user_name /home/$user_name/.zshrc.local
}
echo 'Downloading ZSH profiles from https://grml.org/zsh/'
zsh_config

starship_install () {
    wget -q -O /tmp/starship-latest.tar.gz https://github.com/starship/starship/releases/latest/download/starship-x86_64-unknown-linux-gnu.tar.gz
    tar -xf /tmp/starship-latest.tar.gz -C /usr/local/bin/
    rm /tmp/starship-latest.tar.gz
}
echo 'Installing Starship Cross-Shell'
starship_install

start_ufw () {
    ufw enable
}
start_ufw

set_alias () {
    cat files/alias >> /home/$user_name/.zshrc.local
}
echo 'Creating aliases on ~/.zshrc.local'
set_alias

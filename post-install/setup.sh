#!/bin/bash

tasks/01-prepare-network.sh
tasks/02-configure-system.sh
tasks/03-deploy-plasma.sh
tasks/04-extra-packages.sh

echo 'Setup complete!'
sleep 1

systemctl reboot

#!/bin/bash

tasks/01-prepare-network.sh > /dev/null 2>&1
tasks/02-configure-system.sh > /dev/null 2>&1
tasks/03-deploy-plasma.sh > /dev/null 2>&1
tasks/04-extra-packages.sh > /dev/null 2>&1

echo 'Setup complete!'
sleep 1

systemctl reboot

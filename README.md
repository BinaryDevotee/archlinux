# archlinux
Files to simplify and automate the deployment of my Arch Linux deployments.
The content of this repo can be found in the following directories:

- installation

Inside the 'installation' directory, there are two installation profiles available for you to use, bare metal and virtual machine.
The bare metal scripts are designed to be installed on a laptop or desktop, and inside this directory, there are three files:

1. install.sh
This script installs Arch Linux on a UEFI using Systemd-Boot as the boot loader.

2. install-lts.sh
This script is identical as the previous one, but configures the LTS kernel.

3. install-encrypted-v1.sh
This scripts installs Arch Linux on an encrypted partition.
I will soon create a second version of this script to use LUKS + LVM.

- post-install

In this directory you can find script files that will configure Arch Linux once it's installed, such as adding my user, giving it root privileges, set and define timezone and hostname.
Additioanlly, I am working on scripts to deploy Plasma and Openbox, as these are my desktop environment and window manager of choice.
This is still not nearly as polished as I want and there's still to be changed here.

- roles

Here you can find ways to configure your Arch Linux box. For the time being, I have only one role, which is a 'virtualization host'.
The Virtualization Host role sets up Arch Linux to act as a hypervisor and installs the tools for remote management.

# How to install Arch Linux
From the live media, clone the repository (internet connection is required):

`git clone git@github.com:binarydevotee/archlinux.git && cd archlinux`

Specify in which device you want Arch Linux installed, typically '/dev/sda' or '/dev/nvme0n1' on line 8:

`vim installation/<installation-profile>/install.sh`

Launch the file:

`./installation/<installation-profile>/install.sh`

Once you reboot your system, configure Arch with the contents of the /root directory.

# Disclaimer
- These scripts will run non-interactively and they will simply completely erase and try to install Arch Linux in the device you specify in the script file without any prior check or confirmation.
- Keep in mind that they are merely a collection of functions that will be executed one after another without any error handling or pre-checks, so make sure you define the correct storage device.
- I have not tested nor configured these scripts to run out of a flash drive, so most probably they will not work if you try.
- I have written these functions to help me on my personal needs to redeploy my Arch Linux as I like to test new things and I am not afraid to break my installation, so I wanted to have a way to reinstall Arch without wasting time with manual configurations but still be able to have a fresh installation quickly.
- These files are not meant to be an Arch Linux installer, although it will give you a fully functional Arch Linux installation as long as you specify the correct storage device. If you are looking for something more sophisticated, look at archfi -- https://github.com/MatMoul/archfi
- Always, always refer to the Wiki as things might change and I might not be able to update these files on time, and keep in mind that I wrote these files to help me with my own personal needs and I decided to publish them as they might also help you to get your Arch Linux reinstalled in less than two minutes.

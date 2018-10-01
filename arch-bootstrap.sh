#!/bin/bash

#
# Arch Linux Bootstrap Install Script
#
# Author:	xkrajnan
# Updated:	29-09-2018
# License:	Free to use. No guarantees or liability. Use at your own peril.
# 

#set -e
#set -x


# Check root privileges
if [[ $EUID -ne 0 ]]; then
	echo "Must be root!"
	exit 1
fi

# Check arguments
if [[ $# -ne 3 ]]; then
	echo "usage: $(basename $0) <sdX> <hostname> <username>"
	exit 1
fi

# Read root password
read -s -p "Enter new system's root password: " ARCH_PASSWD && echo
read -s -p "Confirm root password: " ARCH_PASSWD_CONFIRM && echo
if [ "$ARCH_PASSWD" != "$ARCH_PASSWD_CONFIRM" ]; then
	echo "ERROR: Inputs do not match! Aborting."
	exit 1
fi


SDX="$1"
ARCH_HOSTNAME="$2"
ARCH_USERNAME="$3"
MNT="`mktemp -td mnt_XXX`"
PACKAGES="base base-devel intel-ucode wpa_supplicant dialog links bash-completion vim xf86-video-intel xorg-server xfce4 xfce4-whiskermenu-plugin geany firefox ttf-dejavu"


# Print setup and ask for final confirmation
echo "The following device will be used to install the system:"
parted ${SDX} print
cat <<- EOF
	New system will be installed at: ${SDX} (check above)
	hostname:	${ARCH_HOSTNAME}
	username:	${ARCH_USERNAME}
	packages:	${PACKAGES}
	mountpoint:	${MNT}

	WARNING: All data will be purged! [${SDX}]
EOF
read -p 'Type "yes" to continue: ' YES
if [ "$YES" != "yes" ]; then
	echo "Aborting."
	exit 1
fi


# Format partition
umount -fR ${SDX}?
yes | mkfs.vfat ${SDX}1
yes | mkfs.ext4 ${SDX}2
yes | mkfs.ext4 ${SDX}3
yes | mkfs.ext4 ${SDX}4


# Bootstrap system
mount ${SDX}2 ${MNT}
mkdir -p ${MNT}/{boot,var,home}
mount ${SDX}1 ${MNT}/boot
mount ${SDX}3 ${MNT}/var
mount ${SDX}4 ${MNT}/home

pacstrap -ciM ${MNT} ${PACKAGES}
genfstab -U ${MNT} >> ${MNT}/etc/fstab


export SDX
export ARCH_USERNAME
export ARCH_HOSTNAME
export ARCH_PASSWD
arch-chroot ${MNT} bash -x < chroot-actions.sh


# Copy this script to the new installation
cp `ls` -t ${MNT}/root

# Unmount partitions
umount -fR ${SDX}?

echo "DONE."
echo

echo "Arch Linux successfully installed at ${SDX}"


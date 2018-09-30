#!/bin/bash

#
# Arch Linux Bootstrap Install Script
#
# Author:	xkrajnan
# Updated:	29-09-2018
# License:	Free to use. No guarantees or liability. Use at your own peril.
# 


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
read -s -p "Enter new system's root password: " PASSWD && echo
read -s -p "Confirm root password: " PASSWD_CONFIRM && echo
if [ "$PASSWD" != "$PASSWD_CONFIRM" ]; then
	echo "ERROR: Inputs do not match! Aborting."
	exit 1
fi


SDX="$1"
HOSTNAME="$2"
USERNAME="$3"
MNT="`mktemp -td mnt_XXX`"
PACKAGES="base base-devel intel-ucode wpa_supplicant dialog links bash-completion vim xf86-video-intel xorg-server xfce4 xfce4-whiskermenu-plugin geany firefox ttf-dejavu"


# Print setup and ask for final confirmation
echo "The following device will be used to install the system:"
parted ${SDX} print
cat <<- EOF
	New system will be installed at: ${SDX} (check above)
	hostname:	${HOSTNAME}
	username:	${USERNAME}
	packages:	${PACKAGES} (can be selected later)
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

pacstrap -iM ${MNT} ${PACKAGES}
genfstab -U ${MNT} >> ${MNT}/etc/fstab


arch-chroot ${MNT} /bin/bash <<- CHROOT
	# Initialize timezone
	ln -sf /usr/share/zoneinfo/Europe/Prague /etc/localtime

	# Initialize charsets
	sed -i '/#en_US.UTF-8\|#cs_CZ.UTF-8/s/^#//' /etc/locale.gen
	locale-gen
	echo "LANG=en_US.UTF8" > /etc/locale.conf

	# Initialize network
	echo "${HOSTNAME}" > /etc/hostname
	cat <<- EOF >> /etc/hosts
		127.0.0.1	localhost
		::1	localhost
		127.0.1.1	${HOSTNAME}.localdomain	${HOSTNAME}
	EOF

	# Install bootloader
	bootctl --path=/boot install
	cat <<- EOF > /boot/loader/loader.conf
		default	arch*
		timeout	0
		editor	0
	EOF
	cat <<- EOF > /boot/loader/entries/arch.conf
		title	Arch Linux (${HOSTNAME})
		linux	/vmlinuz-linux
		initrd	/intel-ucode.img
		initrd	/initramfs-linux.img
		options	root=PARTUUID=`blkid -s PARTUUID -o value ${SDX}2` rw
	EOF

	# Initialize users
	groupadd ${USERNAME}
	useradd -m -g ${USERNAME} -G wheel -s /bin/bash ${USERNAME}
	echo "${USERNAME}:${PASSWD}" | chpasswd
	echo "root:${PASSWD}" | chpasswd
	sed -i '/%wheel ALL=(ALL) ALL/s/^# //' /etc/sudoers

	cat <<- EOF >> /etc/vimrc
		
		# xkrajnan
		set mouse=""
		set tabstop=4
		set autoindent
		set ignorecase
		set smartcase
		set hlsearch
		filetype plugin on
	EOF
CHROOT


# Copy this script to the new installation
cp "$0" -t ${MNT}/root

# Unmount partitions
umount -fR ${SDX}?

echo "DONE."
echo

echo "Arch Linux successfully installed at ${SDX}"


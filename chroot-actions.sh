#!/bin/false

# Initialize timezone
ln -sf /usr/share/zoneinfo/Europe/Prague /etc/localtime

# Initialize charsets
sed -i.orig '/#en_US.UTF-8\|#cs_CZ.UTF-8/s/^#//' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF8" > /etc/locale.conf

# Initialize network
echo "${ARCH_HOSTNAME}" > /etc/hostname
cat <<- EOF >> /etc/hosts
127.0.0.1	localhost
::1	localhost
127.0.1.1	${ARCH_HOSTNAME}.localdomain	${ARCH_HOSTNAME}
EOF

# Install bootloader
bootctl --path=/boot install
cat <<- EOF > /boot/loader/loader.conf
default	arch*
timeout	0
editor	0
EOF
cat <<- EOF > /boot/loader/entries/arch.conf
title	Arch Linux (${ARCH_HOSTNAME})
linux	/vmlinuz-linux
initrd	/intel-ucode.img
initrd	/initramfs-linux.img
options	root=PARTUUID=`blkid -s PARTUUID -o value ${SDX}2` rw
EOF

# Initialize users
groupadd ${ARCH_USERNAME}
useradd -m -g ${ARCH_USERNAME} -G wheel -s /bin/bash ${ARCH_USERNAME}
echo "${ARCH_USERNAME}:${ARCH_PASSWD}" | chpasswd
echo "root:${ARCH_PASSWD}" | chpasswd
sed -i.orig '/%wheel ALL=(ALL) ALL/s/^# //' /etc/sudoers

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

# clear history ?


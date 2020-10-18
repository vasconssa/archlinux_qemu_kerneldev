#!/bin/bash

set -uo pipefail
trap 's=$?; echo "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR

archive=/tmp/bootstrap.tar.gz
mountpoint=/tmp/arch
keymap=personal.map

bootstarp_url=$(dialog --stdout --inputbox "Enter bootstrap image file url, choose a image from one of this mirrors:https://www.archlinux.org/download" 0 0 "http://br.mirror.archlinux-br.org/iso/2020.10.01/archlinux-bootstrap-2020.10.01-x86_64.tar.gz")
clear


if [[ ! -f $archive ]]; then
    wget $bootstarp_url -O $archive
fi

mkdir -p $mountpoint
image=$(dialog --stdout --inputbox "Enter qemu raw image name" 0 0 "arch_raw.img")
clear
image=images/${image}

qemu-img create -f raw $image 4G

loop=$(sudo losetup --show -f -P $image)
sudo parted $loop mklabel msdos
sudo parted -a optimal $loop mkpart primary 1Mib 100%
sudo parted $loop set 1 boot on
loopp=${loop}
sudo mkfs.ext4 $loopp

sudo mount $loopp $mountpoint
sudo tar xf $archive -C $mountpoint --strip-components 1

hostname=$(dialog --stdout --inputbox "Enter hostname" 0 0 "arch_kernel")
clear

sudo mkdir -p $mountpoint/usr/local/share/kbd/keymaps/
sudo cp $keymap $mountpoint/usr/local/share/kbd/keymaps/personal.map

sudo genfstab -U $mountpoint | sudo tee $mountpoint/etc/fstab > /dev/null
sudo pacstrap $mountpoint base networkmanager tmux vim

sudo $mountpoint/bin/arch-chroot $mountpoint /bin/bash << EOL
set -v

pacman-key --init
pacman-key --populate archlinux

pacman -Syu --noconfirm

systemctl enable NetworkManager.service

ln -s /usr/share/zoneinfo/GMT /etc/localtime
hwclock --systock

echo en_US.UTF-8 UTF-8 >> /etc/locale.gen
locale-gen
echo LANG=en_US.UTF-8 > /etc/locale.conf
echo $hostname > /etc/hostname
echo -e '127.0.0.1  localhost\n::1  localhost' >> /etc/hosts
echo 'KEYMAP=/usr/local/share/kbd/keymaps/personal.map' > /etc/vconsole.conf
passwd -d root
exit
EOL

sudo umount $mountpoint
sudo losetup -d $loop

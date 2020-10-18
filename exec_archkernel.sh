#!/bin/bash

KERNEL=$(dialog --stdout --inputbox "Enter kernel bzImage path" 0 0 "git/kernels/staging/arch/x86/boot/bzImage")
clear
RAM=2G
DISK=$(dialog --stdout --inputbox "Enter raw image" 0 0 "images/arch_raw.img")
clear

qemusystem=$(dialog --stdout --inputbox "Enter qemu-system executable for desired architecture" 0 0 "qemu-system-x86_64")
clear

$qemusystem \
    -enable-kvm     \
    -cpu host   \
    -smp 2  \
    -hda $DISK  \
    -nic user,hostfwd=tcp::10022-:22 \
    -m $RAM     \
    -kernel $KERNEL     \
    -append "root=/dev/sda rw console=ttyS0,1152200 acpi=off nokaslr mode:1920x1080"   \
    -nographic 

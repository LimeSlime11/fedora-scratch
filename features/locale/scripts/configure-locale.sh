#!/bin/bash
set -e

# Set timezone
ln -sf /usr/share/zoneinfo/Europe/Copenhagen /etc/localtime

# Set console keyboard layout
printf '%s\n' 'KEYMAP=dk' > /etc/vconsole.conf

# Set system-wide keyboard layout
localectl set-x11-keymap dk
localectl set-keymap dk

# im not sure if the x11 line is necessary cause we run wayland, but it doesnt hurt to have it there
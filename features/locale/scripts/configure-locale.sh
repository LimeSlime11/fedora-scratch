#!/bin/bash
set -e

# Set timezone
ln -sf /usr/share/zoneinfo/Europe/Copenhagen /etc/localtime

# Set console keyboard layout
printf '%s\n' 'KEYMAP=dk' > /etc/vconsole.conf

# Set system-wide keyboard layout
localectl set-x11-keymap dk
localectl set-keymap dk
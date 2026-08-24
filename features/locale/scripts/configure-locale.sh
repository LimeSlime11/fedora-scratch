#!/bin/bash
set -e

# Set timezone
ln -sf /usr/share/zoneinfo/Europe/Copenhagen /etc/localtime

# Set console keyboard layout
printf '%s\n' 'KEYMAP=dk' > /etc/vconsole.conf
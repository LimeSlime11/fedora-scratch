#!/bin/bash
set -e

if ! id guest >/dev/null 2>&1; then
    useradd \
        --create-home \
        --shell /bin/bash \
        guest
fi

# Ensure the guest owns only its own home directory
chown -R guest:guest /home/guest
chmod 700 /home/guest

# Allow passwordless authentication
passwd -d guest

# Prevent the account from gaining administrative privileges
gpasswd -d guest wheel 2>/dev/null || true
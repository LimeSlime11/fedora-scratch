#!/bin/bash
set -e

GUEST="guest"
HOME_DIR="/home/$GUEST"

# Clean up existing Guest account
if id "$GUEST" >/dev/null 2>&1; then

    # Stop all Guest sessions and processes
    loginctl terminate-user "$GUEST" 2>/dev/null || true
    sleep 1
    pkill -KILL -u "$GUEST" 2>/dev/null || true

    # Remove Guest's home directory
    rm -rf "$HOME_DIR"

    # Remove Guest-owned temporary files
    find /tmp /var/tmp -user "$GUEST" -delete 2>/dev/null || true

    # Remove the Guest account
    userdel "$GUEST"

    # Create a fresh Guest account from /etc/skel
    useradd \
        --create-home \
        --shell /bin/bash \
        "$GUEST"

    # Guest has no password
    passwd -d "$GUEST"

    # Secure the home directory
    chmod 700 "$HOME_DIR"
    chown -R "$GUEST:$GUEST" "$HOME_DIR"

    # Restore SELinux labels
    restorecon -RF "$HOME_DIR"

fi


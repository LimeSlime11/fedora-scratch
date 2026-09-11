#!/bin/bash
set -e

USER="guest"
HOME_DIR="/home/$USER"
TEMPLATE_DIR="/var/lib/$USER-home-template"
WORK_DIR="/var/tmp/$USER-session"

# Skip non-guest users
if [ "$PAM_USER" != "$USER" ]; then
    exit 0
fi

# 1. Create the pristine user home template if it doesn't exist
if [ ! -d "$TEMPLATE_DIR" ]; then
    mkdir -p "$TEMPLATE_DIR"

    # Copy the original build-time user home into the template
    cp -a "$HOME_DIR/." "$TEMPLATE_DIR/"

    # Make sure the template belongs to the user
    chown -R "$USER:$USER" "$TEMPLATE_DIR"
fi

# 2. Clean previous session
umount -l "$HOME_DIR" 2>/dev/null || true
rm -rf "$WORK_DIR" 2>/dev/null || true

# Clean rogue user files in /tmp and /var/tmp
find /tmp /var/tmp -maxdepth 1 -user "$USER" -exec rm -rf {} + 2>/dev/null || true

# 3. Recreate temporary OverlayFS storage
mkdir -p "$WORK_DIR/upper" "$WORK_DIR/work" "$HOME_DIR"

# 4. Mount the user home overlay
mount -t overlay overlay \
  -o lowerdir="$TEMPLATE_DIR",upperdir="$WORK_DIR/upper",workdir="$WORK_DIR/work",context="system_u:object_r:user_home_dir_t:s0" \
  "$HOME_DIR"

# 5. Set permissions
chown -R "$USER:$USER" "$WORK_DIR/upper" "$HOME_DIR"
chmod 755 "$HOME_DIR"
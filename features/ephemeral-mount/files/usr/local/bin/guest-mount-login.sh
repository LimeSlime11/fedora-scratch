#!/bin/bash
set -e

USER="guest"
HOME_DIR="/home/guest"
WORK_DIR="/var/tmp/guest-session"

# Skip non-guest users
if [ "$PAM_USER" != "$USER" ]; then
    exit 0
fi

# 1. Clean previous session & rogue guest files in /tmp or /var/tmp
umount -l "$HOME_DIR" 2>/dev/null || true
rm -rf "$WORK_DIR" 2>/dev/null || true
find /tmp /var/tmp -maxdepth 1 -user "$USER" -exec rm -rf {} + 2>/dev/null || true

# 2. Recreate storage dirs
mkdir -p "$WORK_DIR/upper" "$WORK_DIR/work" "$HOME_DIR"

# 3. Mount OverlayFS with SELinux context
mount -t overlay overlay \
  -o lowerdir=/etc/skel,upperdir=$WORK_DIR/upper,workdir=$WORK_DIR/work,context="system_u:object_r:user_home_dir_t:s0" \
  "$HOME_DIR"

# 4. Set permissions
chown -R $USER:$USER "$WORK_DIR/upper" "$HOME_DIR"
chmod 755 "$HOME_DIR"
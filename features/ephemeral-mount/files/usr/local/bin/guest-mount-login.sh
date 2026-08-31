#!/bin/bash
USER="guest"
HOME_DIR="/home/guest"
WORK_DIR="/var/tmp/guest-session"

# 1. Clean up any stale session directories from prior boots/crashes
umount -l "$HOME_DIR" 2>/dev/null
rm -rf "$WORK_DIR"

# 2. Create physical disk directories for OverlayFS
mkdir -p "$WORK_DIR/upper" "$WORK_DIR/work"

# 3. Mount OverlayFS: Lower is /etc/skel, Upper is physical disk space
mount -t overlay overlay \
  -o lowerdir=/etc/skel,upperdir=$WORK_DIR/upper,workdir=$WORK_DIR/work \
  "$HOME_DIR"

# 4. Enforce user ownership
chown -R $USER:$USER "$HOME_DIR"
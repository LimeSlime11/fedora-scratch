#!/bin/bash
# Exit immediately on any unhandled command error
set -e

USER="guest"
HOME_DIR="/home/guest"
WORK_DIR="/var/tmp/guest-session"

# 0. Exit cleanly if the logging-in user is NOT guest
if [ "$PAM_USER" != "$USER" ]; then
    exit 0
fi

# 1. Force unmount any stale mounts cleanly (errors ignored so fresh boot doesn't trip set -e)
umount -l "$HOME_DIR" 2>/dev/null || true
rm -rf "$WORK_DIR" 2>/dev/null || true

# 2. Re-create work directories
mkdir -p "$WORK_DIR/upper" "$WORK_DIR/work" "$HOME_DIR"

# 3. Mount OverlayFS WITH SELinux context option
# If this fails, 'set -e' immediately triggers script failure -> PAM aborts -> SDDM kicks to login
mount -t overlay overlay \
  -o lowerdir=/etc/skel,upperdir=$WORK_DIR/upper,workdir=$WORK_DIR/work,context="system_u:object_r:user_home_t:s0" \
  "$HOME_DIR"

# 4. Correct permissions (MUST succeed, no || true)
chown -R $USER:$USER "$WORK_DIR/upper" "$HOME_DIR"
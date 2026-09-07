#!/bin/bash
set -e

APPLET_SRC="/etc/skel/.config/plasma-org.kde.plasma.desktop-appletsrc"
CONFIG="/etc/pinned-apps.conf"

if [ ! -f "$APPLET_SRC" ]; then
    echo "Plasma appletsrc not found, skipping taskbar configuration."
    exit 0
fi

if [ ! -f "$CONFIG" ]; then
    echo "Plasma icons configuration not found, skipping taskbar configuration."
    exit 0
fi

# Read configured launchers, ignoring empty lines and comments.
mapfile -t PINNED_APPS < <(
    sed \
        -e 's/#.*//' \
        -e '/^[[:space:]]*$/d' \
        "$CONFIG"
)

if [ "${#PINNED_APPS[@]}" -eq 0 ]; then
    echo "No taskbar launchers configured."
    exit 0
fi

# Join the launchers with commas.
LAUNCHERS=$(IFS=,; echo "${PINNED_APPS[*]}")

# Replace the existing launchers= line.
if grep -q '^launchers=' "$APPLET_SRC"; then
    sed -i "s|^launchers=.*|launchers=$LAUNCHERS|" "$APPLET_SRC"
else
    echo "No launchers= line found in $APPLET_SRC"
    exit 1
fi

echo "Configured Plasma taskbar:"
echo "$LAUNCHERS"
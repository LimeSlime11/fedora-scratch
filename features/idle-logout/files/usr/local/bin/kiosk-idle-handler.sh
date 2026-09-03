#!/bin/bash

# Only run for the guest user
if [ "$(whoami)" != "guest" ]; then
    exit 0
fi

# Ensure GTK and Qt apps find the active Wayland session
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export GDK_BACKEND=wayland

# Display Zenity dialog with a live 30-second timeout
zenity --question \
       --title="Inaktivitet" \
       --text="Om 30 sekunder bliver du logget ud, og dine data bliver slettet. Vil du annullere?" \
       --ok-label="Log ud" \
       --cancel-label="Annuller" \
       --timeout=30 \
       --modal

EXIT_CODE=$?

# Exit code 1 = User clicked "Annuller"
if [ "$EXIT_CODE" -eq 1 ]; then
    # User cancelled: exit cleanly to resume session
    exit 0
else
    # Exit code 0 (Log ud) or 5 (Timeout expired): trigger logout
    qdbus-qt6 org.kde.LogoutPrompt /LogoutPrompt promptLogout
fi

# the logout method used throws a 30 second logout timer, as per usual KDE behavior, so with the 30 second zenity timeout, the user has a total of 60 seconds to cancel the logout before the session is terminated. right now this adds up to exactly 3 minutes of inactivity before the session is terminated, technically with two different warnings, the zenity popup, then the screen dimming timer. this makes it hard to miss and get logged out without seeing the warnings.
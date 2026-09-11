#!/bin/bash

# Only run for the guest user
if [ "$(whoami)" != "guest" ]; then
    exit 0
fi

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
    # Exit code 0 (Log ud) or 5 (Timeout expired):
    # log out through XFCE
    xfce4-session-logout --logout
fi
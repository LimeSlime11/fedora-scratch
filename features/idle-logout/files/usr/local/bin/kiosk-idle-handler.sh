#!/bin/bash

# Trigger kdialog with a 30-second timeout
kdialog --title "Library Kiosk" \
        --warningcontinuecancel "Session expiring due to inactivity. Unsaved data will be lost!" \
        --timeout 30

EXIT_CODE=$?

# Exit code 0 = Clicked Continue / Timer Expired
# Exit code 2 = Timeout Expired (kdialog native timeout code)
if [ "$EXIT_CODE" -eq 0 ] || [ "$EXIT_CODE" -eq 2 ]; then
    # Perform immediate forced session logout
    qdbus-qt6 org.kde.LogoutPrompt /LogoutPrompt promptLogout
fi
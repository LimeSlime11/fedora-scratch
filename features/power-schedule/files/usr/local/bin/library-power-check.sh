#!/usr/bin/env bash

set -euo pipefail

CONFIG="/etc/library-schedule.conf"

# Users who prevent the computer from going to sleep.
PROTECTED_USERS=("admin")

# How often to check the schedule and login state.
CHECK_INTERVAL=60

# ==============================================================================
# Load configuration
# ==============================================================================

if [[ ! -f "$CONFIG" ]]; then
    echo "ERROR: Schedule configuration not found: $CONFIG"
    exit 1
fi

# shellcheck disable=SC1090
source "$CONFIG"

# ==============================================================================
# Validate rtcwake mode
# ==============================================================================

case "$mode" in
    freeze|mem|disk|off)
        ;;
    *)
        echo "ERROR: Invalid rtcwake mode: $mode"
        exit 1
        ;;
esac

# ==============================================================================
# Main loop
# ==============================================================================

while true; do

    # ==========================================================================
    # Current date/time
    # ==========================================================================

    CURRENT_DATE=$(date '+%Y-%m-%d')
    CURRENT_TIME=$(date '+%H:%M')

    #LC_ALL=C is used to ensure that the day abbreviation is in English, regardless of the system locale.
    DAY=$(LC_ALL=C date '+%a' | tr '[:upper:]' '[:lower:]')

    OPEN_VAR="${DAY}_open"
    CLOSE_VAR="${DAY}_close"

    OPEN="${!OPEN_VAR:-}"
    CLOSE="${!CLOSE_VAR:-}"

    # ==========================================================================
    # Check whether the library is currently open
    # ==========================================================================

    # bash does not allow => or >=, so the opening time will be 1 minute later than specified...
    if [[ -n "$OPEN" && -n "$CLOSE" ]]; then
        if [[ "$CURRENT_TIME" > "$OPEN" && "$CURRENT_TIME" < "$CLOSE" ]]; then
            sleep "$CHECK_INTERVAL"
            continue
        fi
    fi

    # ==========================================================================
    # Check whether a protected user is logged in
    # ==========================================================================

    USER_LOGGED_IN=false

    for USER in "${PROTECTED_USERS[@]}"; do
        if loginctl list-users --no-legend | awk '{print $2}' | grep -qx "$USER"; then
            USER_LOGGED_IN=true
            break
        fi
    done

    if [[ "$USER_LOGGED_IN" == true ]]; then
        sleep "$CHECK_INTERVAL"
        continue
    fi

    # ==========================================================================
    # Find the next opening time
    # ==========================================================================

    NEXT_OPEN=""

    for DAYS_AHEAD in {0..7}; do

        CHECK_DATE=$(date -d "$CURRENT_DATE + $DAYS_AHEAD days" '+%Y-%m-%d')
        CHECK_DAY=$(LC_ALL=C date -d "$CHECK_DATE" '+%a' | tr '[:upper:]' '[:lower:]')

        OPEN_VAR="${CHECK_DAY}_open"
        OPEN="${!OPEN_VAR:-}"

        # This day is closed.
        [[ -z "$OPEN" ]] && continue

        # Don't select an opening time that has already passed today.
        if [[ "$DAYS_AHEAD" -eq 0 && "$CURRENT_TIME" > "$OPEN" ]]; then
            continue
        fi

        NEXT_OPEN="$CHECK_DATE $OPEN"
        break
    done

    # ==========================================================================
    # Make sure we found an opening time
    # ==========================================================================

    if [[ -z "$NEXT_OPEN" ]]; then
        echo "ERROR: Could not find next opening time."
        exit 1
    fi

    # ==========================================================================
    # Convert next opening to Unix timestamp
    # ==========================================================================

    WAKE_TIME=$(date -d "$NEXT_OPEN" '+%s')
    CURRENT_TIMESTAMP=$(date '+%s')

    if [[ "$WAKE_TIME" -le "$CURRENT_TIMESTAMP" ]]; then
        echo "ERROR: Calculated wake time is in the past."
        exit 1
    fi

    # ==========================================================================
    # Suspend
    # ==========================================================================

    echo "Library is closed."
    echo "No protected users are logged in."
    echo "Next opening: $NEXT_OPEN"
    echo "Using rtcwake mode: $mode"

    # we are going to restart sddm, to log out unprotected users, and prevent a certain bug on wakeup when sddm is the only running graphical environment
    systemctl stop sddm.service

    rtcwake \
        --utc \
        --mode "$mode" \
        --time "$WAKE_TIME"

    systemctl start sddm.service
    # ==========================================================================
    # Wait briefly before checking everything again.
    # ==========================================================================

    sleep "$CHECK_INTERVAL"

done
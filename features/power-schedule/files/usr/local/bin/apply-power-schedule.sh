#!/usr/bin/env bash

set -euo pipefail

# ==============================================================================
# Configuration
# ==============================================================================

SCHEDULE_FILE="/etc/library-schedule.conf"
RTC_WAKEALARM="/sys/class/rtc/rtc0/wakealarm"

# ==============================================================================
# Helper functions
# ==============================================================================

log() {
    echo "[library-power] $*"
}

# Return the configuration prefix for today's weekday.
get_today_prefix() {
    case "$(date +%u)" in
        1) echo "mon" ;;
        2) echo "tue" ;;
        3) echo "wed" ;;
        4) echo "thu" ;;
        5) echo "fri" ;;
        6) echo "sat" ;;
        7) echo "sun" ;;
    esac
}

# Return the configuration prefix for a date.
get_day_prefix() {
    local date="$1"

    case "$(date -d "$date" +%u)" in
        1) echo "mon" ;;
        2) echo "tue" ;;
        3) echo "wed" ;;
        4) echo "thu" ;;
        5) echo "fri" ;;
        6) echo "sat" ;;
        7) echo "sun" ;;
    esac
}

# ==============================================================================
# Load configuration
# ==============================================================================

if [[ ! -f "$SCHEDULE_FILE" ]]; then
    log "No schedule file found: $SCHEDULE_FILE"
    log "Nothing to do."
    exit 0
fi

# The configuration file contains only simple variable assignments.
source "$SCHEDULE_FILE"

# ==============================================================================
# Validate configuration
# ==============================================================================

TIME_REGEX='^([01][0-9]|2[0-3]):[0-5][0-9]$'

validate_time() {
    local name="$1"
    local value="$2"

    if [[ -z "$value" ]]; then
        return 0
    fi

    if [[ ! "$value" =~ $TIME_REGEX ]]; then
        log "ERROR: Invalid time for $name: '$value'"
        log "Expected HH:MM."
        exit 1
    fi
}

validate_time "mon_open"  "${mon_open:-}"
validate_time "mon_close" "${mon_close:-}"

validate_time "tue_open"  "${tue_open:-}"
validate_time "tue_close" "${tue_close:-}"

validate_time "wed_open"  "${wed_open:-}"
validate_time "wed_close" "${wed_close:-}"

validate_time "thu_open"  "${thu_open:-}"
validate_time "thu_close" "${thu_close:-}"

validate_time "fri_open"  "${fri_open:-}"
validate_time "fri_close" "${fri_close:-}"

validate_time "sat_open"  "${sat_open:-}"
validate_time "sat_close" "${sat_close:-}"

validate_time "sun_open"  "${sun_open:-}"
validate_time "sun_close" "${sun_close:-}"

# ==============================================================================
# Determine today's schedule
# ==============================================================================

TODAY=$(date +%Y-%m-%d)
TODAY_PREFIX=$(get_today_prefix)

OPEN_VARIABLE="${TODAY_PREFIX}_open"
CLOSE_VARIABLE="${TODAY_PREFIX}_close"

OPEN_TIME="${!OPEN_VARIABLE:-}"
CLOSE_TIME="${!CLOSE_VARIABLE:-}"

NOW=$(date +%s)

log "Current date/time: $(date '+%Y-%m-%d %H:%M:%S')"
log "Today: $TODAY_PREFIX"

# ==============================================================================
# Schedule today's shutdown
# ==============================================================================

OUTSIDE_HOURS=false

if [[ -n "$OPEN_TIME" && -n "$CLOSE_TIME" ]]; then

    CLOSE_TIMESTAMP=$(date -d "$TODAY $CLOSE_TIME" +%s)

    if (( NOW < CLOSE_TIMESTAMP )); then

        log "Library is currently open."
        log "Today's closing time: $CLOSE_TIME"

        # Let systemd/shutdown handle the actual countdown.
        # Using HH:MM avoids calculating a number of minutes ourselves.
        log "Scheduling shutdown for $CLOSE_TIME."

        /usr/sbin/shutdown \
            -h "$CLOSE_TIME" \
            "Library is closing soon. Wrapping up session."

    else

        log "Library has already closed today."
        OUTSIDE_HOURS=true

    fi

else

    log "Library is closed today."
    OUTSIDE_HOURS=true

fi

# ==============================================================================
# Find next opening time
# ==============================================================================

NEXT_OPEN=""

for DAYS_AHEAD in {1..7}; do

    LOOKAHEAD_DATE=$(date -d "$TODAY +$DAYS_AHEAD days" +%Y-%m-%d)
    DAY_PREFIX=$(get_day_prefix "$LOOKAHEAD_DATE")

    OPEN_VARIABLE="${DAY_PREFIX}_open"
    LOOKAHEAD_OPEN="${!OPEN_VARIABLE:-}"

    if [[ -n "$LOOKAHEAD_OPEN" ]]; then
        NEXT_OPEN="$LOOKAHEAD_DATE $LOOKAHEAD_OPEN"
        break
    fi

done

# ==============================================================================
# Program RTC wake alarm
# ==============================================================================

if [[ -n "$NEXT_OPEN" ]]; then

    WAKE_TIMESTAMP=$(date -d "$NEXT_OPEN" +%s)

    log "Next library opening: $NEXT_OPEN"
    log "RTC wake timestamp: $WAKE_TIMESTAMP"

    if [[ ! -e "$RTC_WAKEALARM" ]]; then
        log "WARNING: RTC wakealarm is not available:"
        log "         $RTC_WAKEALARM"
    else

        # Clear existing alarm.
        if ! echo 0 > "$RTC_WAKEALARM"; then
            log "WARNING: Could not clear existing RTC alarm."
        fi

        # Set new alarm.
        if echo "$WAKE_TIMESTAMP" > "$RTC_WAKEALARM"; then
            log "RTC wake alarm successfully programmed."
        else
            log "ERROR: Failed to program RTC wake alarm."
        fi

    fi

else

    log "WARNING: No future opening time found."

fi

# ==============================================================================
# Maintenance boot
# ==============================================================================

if [[ "$OUTSIDE_HOURS" == true ]]; then

    log "System booted outside library hours."
    log "Scheduling shutdown in 5 minutes."

    /usr/sbin/shutdown \
        -h +5 \
        "Maintenance window complete. Shutting down."

fi

log "Library power scheduler finished."
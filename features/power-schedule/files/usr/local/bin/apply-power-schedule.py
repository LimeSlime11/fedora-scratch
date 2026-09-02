#!/usr/bin/env python3

import datetime
import json
import math
import os
import subprocess
import sys

# ============================================================================
# CONFIGURATION
# ============================================================================

# Path to the JSON configuration file containing library hours.
SCHEDULE_FILE = "/etc/library-schedule.json"

# RTC device used for hardware wake alarms.
RTC_WAKEALARM = "/sys/class/rtc/rtc0/wakealarm"

# Python weekday numbers:
# 0 = Monday, 1 = Tuesday, ..., 6 = Sunday
WEEKDAYS = ["mon", "tue", "wed", "thu", "fri", "sat", "sun"]


# ============================================================================
# LOGGING
# ============================================================================

def log(message):
    """Print a message and flush immediately for systemd/journal logging."""
    print(message, flush=True)


# ============================================================================
# SCHEDULE
# ============================================================================

def get_schedule():
    """Read and parse the library schedule JSON file."""
    try:
        with open(SCHEDULE_FILE, "r", encoding="utf-8") as f:
            schedule = json.load(f)
    except FileNotFoundError:
        log(f"ERROR: Schedule file not found: {SCHEDULE_FILE}")
        return None
    except json.JSONDecodeError as e:
        log(f"ERROR: Invalid JSON in {SCHEDULE_FILE}: {e}")
        return None
    except OSError as e:
        log(f"ERROR: Could not read {SCHEDULE_FILE}: {e}")
        return None

    if not isinstance(schedule, dict):
        log("ERROR: Schedule configuration must contain a JSON object.")
        return None

    return schedule


def parse_time(time_string, description):
    """
    Convert an HH:MM string into a datetime.time object.

    Returns None if the value is invalid.
    """
    if not isinstance(time_string, str):
        log(f"WARNING: Invalid {description}: expected HH:MM string.")
        return None

    try:
        return datetime.datetime.strptime(
            time_string,
            "%H:%M"
        ).time()
    except ValueError:
        log(
            f"WARNING: Invalid {description}: "
            f"'{time_string}' (expected HH:MM)."
        )
        return None


# ============================================================================
# RTC
# ============================================================================

def clear_rtc_alarm():
    """
    Clear any existing RTC wake alarm.

    Linux requires the wakealarm state to be cleared before programming
    another alarm on many RTC implementations.
    """
    try:
        with open(RTC_WAKEALARM, "w", encoding="ascii") as f:
            f.write("0")
        return True

    except FileNotFoundError:
        log(f"WARNING: RTC wakealarm not available: {RTC_WAKEALARM}")
        return False

    except PermissionError:
        log(
            "WARNING: Permission denied while clearing RTC alarm. "
            "This script probably needs to run as root."
        )
        return False

    except OSError as e:
        log(f"WARNING: Could not clear RTC alarm: {e}")
        return False


def set_rtc_alarm(target_datetime):
    """
    Program the RTC to wake the machine at target_datetime.

    target_datetime is interpreted as local system time. Python converts it
    into an absolute Unix timestamp, which is what the Linux wakealarm
    interface expects.
    """
    if not clear_rtc_alarm():
        log("WARNING: RTC alarm was not cleared; attempting to continue.")

    try:
        # Convert local datetime to an absolute Unix timestamp.
        timestamp = int(target_datetime.timestamp())

        with open(RTC_WAKEALARM, "w", encoding="ascii") as f:
            f.write(str(timestamp))

        log(
            f"RTC wake alarm set for "
            f"{target_datetime.strftime('%Y-%m-%d %H:%M:%S')}"
        )

        return True

    except FileNotFoundError:
        log(f"ERROR: RTC wakealarm not available: {RTC_WAKEALARM}")
        return False

    except PermissionError:
        log(
            "ERROR: Permission denied while setting RTC alarm. "
            "This script probably needs to run as root."
        )
        return False

    except OSError as e:
        log(f"ERROR: Failed to write RTC wakealarm: {e}")
        return False


# ============================================================================
# SHUTDOWN
# ============================================================================

def schedule_shutdown(delay_minutes, message):
    """
    Schedule a system shutdown using systemd's shutdown command.

    delay_minutes is always rounded up to avoid accidentally scheduling
    shutdown immediately when only a few seconds remain.
    """
    delay_minutes = max(1, int(delay_minutes))

    try:
        subprocess.run(
            [
                "/usr/sbin/shutdown",
                "-h",
                f"+{delay_minutes}",
                message,
            ],
            check=True,
        )

        log(f"Shutdown scheduled in {delay_minutes} minute(s).")
        return True

    except FileNotFoundError:
        log("ERROR: /usr/sbin/shutdown was not found.")
        return False

    except subprocess.CalledProcessError as e:
        log(f"ERROR: Failed to schedule shutdown: {e}")
        return False

    except OSError as e:
        log(f"ERROR: Could not execute shutdown: {e}")
        return False


# ============================================================================
# SCHEDULE CALCULATIONS
# ============================================================================

def get_next_opening(schedule, now):
    """
    Find the next library opening after the current date.

    Searches up to seven days ahead.
    """
    for days_ahead in range(1, 8):
        date = now.date() + datetime.timedelta(days=days_ahead)
        weekday_key = WEEKDAYS[date.weekday()]

        rule = schedule.get(weekday_key, {})

        if not isinstance(rule, dict):
            log(
                f"WARNING: Invalid schedule entry for "
                f"{weekday_key}; skipping."
            )
            continue

        open_string = rule.get("open")

        # No opening time means the library is closed that day.
        if not open_string:
            continue

        open_time = parse_time(
            open_string,
            f"opening time for {weekday_key}"
        )

        if open_time is None:
            continue

        return datetime.datetime.combine(date, open_time)

    return None


def evaluate_today(schedule, now):
    """
    Determine whether the machine is currently past today's closing time.

    Returns:
        True  -> outside normal operating hours
        False -> currently before today's closing time
    """
    today_key = WEEKDAYS[now.weekday()]
    today_rule = schedule.get(today_key, {})

    if not isinstance(today_rule, dict):
        log(
            f"WARNING: Invalid schedule entry for {today_key}. "
            "Treating today as closed."
        )
        return True

    close_string = today_rule.get("close")

    # No closing time means there is no active operating period today.
    if not close_string:
        log(f"Library is closed today ({today_key}).")
        return True

    close_time = parse_time(
        close_string,
        f"closing time for {today_key}"
    )

    if close_time is None:
        log(
            f"WARNING: Could not determine today's closing time. "
            "Treating today as closed."
        )
        return True

    closing_datetime = datetime.datetime.combine(
        now.date(),
        close_time
    )

    if now < closing_datetime:
        # Calculate the remaining time.
        seconds_remaining = (
            closing_datetime - now
        ).total_seconds()

        # Round UP so we never accidentally request shutdown immediately
        # because of truncation.
        delay_minutes = max(
            1,
            math.ceil(seconds_remaining / 60)
        )

        log(
            f"Library is currently open. "
            f"Closing time: {close_time.strftime('%H:%M')}"
        )

        log(
            f"Scheduling shutdown for "
            f"{closing_datetime.strftime('%Y-%m-%d %H:%M:%S')} "
            f"({delay_minutes} minute(s) from now)."
        )

        schedule_shutdown(
            delay_minutes,
            "Library is closing soon. Wrapping up session."
        )

        return False

    log(
        f"Library has already closed today "
        f"({close_time.strftime('%H:%M')})."
    )

    return True


# ============================================================================
# MAIN
# ============================================================================

def main():
    log("Library power scheduler starting.")

    # ------------------------------------------------------------------------
    # Check schedule configuration
    # ------------------------------------------------------------------------

    if not os.path.exists(SCHEDULE_FILE):
        log(
            f"No schedule file found at {SCHEDULE_FILE}. "
            "Exiting safely."
        )
        return 0

    schedule = get_schedule()

    if schedule is None:
        log("Unable to load schedule. Exiting safely.")
        return 1

    # Capture the current local date/time.
    now = datetime.datetime.now()

    log(
        f"Current local time: "
        f"{now.strftime('%Y-%m-%d %H:%M:%S')}"
    )

    # ------------------------------------------------------------------------
    # 1. Evaluate today's closing time
    # ------------------------------------------------------------------------

    is_outside_library_hours = evaluate_today(
        schedule,
        now
    )

    # ------------------------------------------------------------------------
    # 2. Find and program the next opening time
    # ------------------------------------------------------------------------

    next_wake_datetime = get_next_opening(
        schedule,
        now
    )

    if next_wake_datetime is not None:
        log(
            f"Next library opening: "
            f"{next_wake_datetime.strftime('%Y-%m-%d %H:%M:%S')}"
        )

        set_rtc_alarm(next_wake_datetime)

    else:
        log(
            "WARNING: No valid opening time found "
            "within the next seven days."
        )

    # ------------------------------------------------------------------------
    # 3. Maintenance boot handling
    # ------------------------------------------------------------------------

    if is_outside_library_hours:
        log(
            "System booted outside active library hours. "
            "Starting 5-minute maintenance window."
        )

        schedule_shutdown(
            5,
            "Maintenance window complete. Shutting down."
        )

    log("Library power scheduler finished.")

    return 0


# ============================================================================
# ENTRY POINT
# ============================================================================

if __name__ == "__main__":
    sys.exit(main())
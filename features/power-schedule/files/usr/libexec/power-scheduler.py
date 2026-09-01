#!/usr/bin/env python3
import os
import json
import time
import subprocess
from datetime import datetime, timedelta

CONFIG_PATH = "/etc/kiosk/power-schedule.json"

def parse_time(time_str):
    h, m = map(int, time_str.split(':'))
    return h, m

def time_to_minutes(time_str):
    h, m = parse_time(time_str)
    return h * 60 + m

def set_display_power(enable=True):
    """Controls screen power on Plasma 6 Wayland."""
    state = "enable" if enable else "disable"
    cmd = f"export WAYLAND_DISPLAY=wayland-0; export XDG_RUNTIME_DIR=/run/user/1000; kscreen-doctor --output.1.{state}"
    subprocess.run(cmd, shell=True, stderr=subprocess.DEVNULL)

def get_next_wake_time(now, config):
    """Scans today and up to 7 future days to find the next opening time."""
    for days_ahead in range(0, 8):
        target_date = now + timedelta(days=days_ahead)
        day_key = str(target_date.isoweekday())
        
        if day_key not in config["schedule"]:
            continue
            
        rule = config["schedule"][day_key]
        
        # Skip if closed all day
        if rule["open_time"] == rule["close_time"]:
            continue
            
        open_h, open_m = parse_time(rule["open_time"])
        candidate_wake = target_date.replace(hour=open_h, minute=open_m, second=0, microsecond=0)
        
        # If checking today, make sure the opening time hasn't already passed
        if days_ahead == 0 and candidate_wake <= now:
            continue
            
        return candidate_wake
    return None

def main():
    print("[+] Kiosk Power Scheduler initialized.")
    display_active = True

    while True:
        if not os.path.exists(CONFIG_PATH):
            time.sleep(10)
            continue

        try:
            with open(CONFIG_PATH, 'r') as f:
                config = json.load(f)
        except Exception as e:
            print(f"[!] Configuration read error: {e}")
            time.sleep(10)
            continue

        now = datetime.now()
        day_key = str(now.isoweekday())
        
        rule = config["schedule"].get(day_key, {"open_time": "00:00", "close_time": "00:00", "closed_state": "screen-off"})
        
        current_mins = now.hour * 60 + now.minute
        open_mins = time_to_minutes(rule["open_time"])
        close_mins = time_to_minutes(rule["close_time"])
        
        is_closed_today = (open_mins == close_mins)
        is_within_hours = (open_mins <= current_mins < close_mins) if not is_closed_today else False

        if is_within_hours:
            # Operational Hours: Ensure display is awake
            if not display_active:
                print("[+] Entering operational hours. Restoring display power.")
                set_display_power(enable=True)
                display_active = True
            time.sleep(60)
        else:
            # Outside Operational Hours
            target_state = rule.get("closed_state", "screen-off")
            next_wake = get_next_wake_time(now, config)
            
            if not next_wake:
                print("[!] No future open hours found in schedule logic.")
                time.sleep(300)
                continue

            seconds_to_sleep = int((next_wake - now).total_seconds())

            if target_state == "screen-off":
                if display_active:
                    print(f"[!] Closed. Blanking screen until {next_wake}")
                    set_display_power(enable=False)
                    display_active = False
                time.sleep(60)
            elif target_state in ["suspend", "off"]:
                rtc_mode = "mem" if target_state == "suspend" else "off"
                print(f"[!] Closed. Entering system '{target_state}' state for {seconds_to_sleep}s until {next_wake}")
                
                # Make sure display is active before sleeping so it recovers cleanly on wake
                set_display_power(enable=True)
                display_active = True
                
                time.sleep(2)
                subprocess.run(f"rtcwake -m {rtc_mode} -s {seconds_to_sleep}", shell=True)
                print("[+] System resumed from RTC alarm.")
                time.sleep(10)

if __name__ == "__main__":
    main()
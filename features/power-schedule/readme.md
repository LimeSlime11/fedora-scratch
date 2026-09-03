## How this feature works

1. The `.service` runs the `.sh` script.
2. The `.sh` script loads the `.conf` configuration file.
3. The `.sh` script enters an infinite loop.
4. The `.sh` script checks whether the library is currently open. If it is, the script waits one minute and repeats the loop.
5. The `.sh` script checks whether any specified protected user is logged in. If one is, the script waits one minute and repeats the loop.
6. If both checks pass, the library is closed and no protected users are logged in.
7. The `.sh` script calculates the next opening time and uses `rtcwake` with the configured power mode to suspend the computer until then.
8. When the computer wakes, `rtcwake` finishes and the script waits one minute before continuing the loop.

If `mode=off` is used, the computer will power off instead of entering a suspend state. An RTC wake alarm is still configured, so the computer may automatically power back on at the next opening time, provided the hardware and firmware support waking from the powered-off state.

If `off` is not desired, use `mem` or `freeze` instead.

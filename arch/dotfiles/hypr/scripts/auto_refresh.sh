#!/usr/bin/env bash

last_state=""

set_refresh() {
    local ac=""
    for p in /sys/class/power_supply/AC* /sys/class/power_supply/ADP* /sys/class/power_supply/Mains*; do
        if [[ -f "$p/online" ]]; then
            ac=$(cat "$p/online" 2>/dev/null)
            break
        fi
    done
    [[ -z "$ac" ]] && ac=$(cat /sys/class/power_supply/ACAD/online 2>/dev/null || true)
    [[ -z "$ac" || "$ac" == "$last_state" ]] && return

    prev_state="$last_state"
    last_state="$ac"

    if [ "$ac" = "1" ]; then
        hyprctl eval 'hl.monitor({ output = "eDP-1", mode = "1920x1080@144.00Hz", position = "0x0", scale = 1.0 })' >/dev/null 2>&1
        [ -n "$prev_state" ] && notify-send -u low -i video-display "Display Refresh Rate" "Switched to 144Hz (AC Connected)"
    else
        hyprctl eval 'hl.monitor({ output = "eDP-1", mode = "1920x1080@60.00Hz", position = "0x0", scale = 1.0 })' >/dev/null 2>&1
        [ -n "$prev_state" ] && notify-send -u low -i video-display "Display Refresh Rate" "Switched to 60Hz (Battery Mode)"
    fi
    killall -SIGUSR2 waybar 2>/dev/null
}

set_refresh

udevadm monitor --subsystem-match=power_supply --udev | while read -r _; do
    set_refresh
done

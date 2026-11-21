#!/usr/bin/env bash
set -eu
for device in /sys/class/leds/*kbd_backlight; do
    [[ -e $device ]] || exit 0
    led=${device##*/}
    current=$(brightnessctl -d "$led" get)
    max=$(brightnessctl -d "$led" max)
    exec brightnessctl -d "$led" set "$(( (current + 1) % (max + 1) ))"
done

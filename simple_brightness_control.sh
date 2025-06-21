#!/bin/bash

# Simple brightness control for JDI backlight
# Works with brightness levels 0-3 (hardware limited)

BACKLIGHT_PATH="/sys/class/backlight/jdi-backlight/brightness"
CURRENT_BRIGHTNESS=$(cat $BACKLIGHT_PATH 2>/dev/null || echo "0")

case "$1" in
    "up")
        NEW_BRIGHTNESS=$((CURRENT_BRIGHTNESS + 1))
        if [ $NEW_BRIGHTNESS -gt 3 ]; then
            NEW_BRIGHTNESS=3
        fi
        echo $NEW_BRIGHTNESS | sudo tee $BACKLIGHT_PATH
        echo "Brightness increased to: $NEW_BRIGHTNESS/3"
        ;;
    "down")
        NEW_BRIGHTNESS=$((CURRENT_BRIGHTNESS - 1))
        if [ $NEW_BRIGHTNESS -lt 0 ]; then
            NEW_BRIGHTNESS=0
        fi
        echo $NEW_BRIGHTNESS | sudo tee $BACKLIGHT_PATH
        echo "Brightness decreased to: $NEW_BRIGHTNESS/3"
        ;;
    "toggle")
        if [ $CURRENT_BRIGHTNESS -eq 0 ]; then
            echo 2 | sudo tee $BACKLIGHT_PATH
            echo "Backlight turned ON (2/3)"
        else
            echo 0 | sudo tee $BACKLIGHT_PATH
            echo "Backlight turned OFF"
        fi
        ;;
    "cycle")
        # Cycle through 0, 1, 2, 3
        case $CURRENT_BRIGHTNESS in
            0) NEW_BRIGHTNESS=1 ;;
            1) NEW_BRIGHTNESS=2 ;;
            2) NEW_BRIGHTNESS=3 ;;
            *) NEW_BRIGHTNESS=0 ;;
        esac
        echo $NEW_BRIGHTNESS | sudo tee $BACKLIGHT_PATH
        echo "Brightness cycled to: $NEW_BRIGHTNESS/3"
        ;;
    [0-3])
        echo $1 | sudo tee $BACKLIGHT_PATH
        echo "Brightness set to: $1/3"
        ;;
    "status")
        echo "Current brightness: $CURRENT_BRIGHTNESS/3"
        echo "Backlight: $([ $CURRENT_BRIGHTNESS -eq 0 ] && echo 'OFF' || echo 'ON')"
        ;;
    *)
        echo "Usage: $0 {up|down|toggle|cycle|0-3|status}"
        echo "Current brightness: $CURRENT_BRIGHTNESS/3"
        ;;
esac

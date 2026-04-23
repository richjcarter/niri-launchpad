#!/bin/bash
# Navigate launchpad/configure selection with arrow keys
# Usage: navigate.sh up|down|left|right

DIRECTION="$1"
EWW_CONFIG="$HOME/.config/eww/launchpad"

# Check if configure window is open - handle it separately
if eww -c "$EWW_CONFIG" active-windows 2>/dev/null | grep -q "configure"; then
    ~/.local/share/launchpad/scripts/configure-handler.sh navigate "$DIRECTION"
    exit 0
fi

# Check if launchpad is visible
if ! eww -c "$EWW_CONFIG" active-windows 2>/dev/null | grep -q "launchpad"; then
    exit 0
fi

# Enable keyboard navigation mode (disables mouse hover)
eww -c "$EWW_CONFIG" update kbd-nav=true

# Reset keyboard nav mode after 2 seconds of no keyboard input
# Kill any existing reset timer
pkill -f "launchpad-kbd-reset" 2>/dev/null
(
    exec -a "launchpad-kbd-reset" sleep 2
    eww -c "$EWW_CONFIG" update kbd-nav=false 2>/dev/null
) &

# Get current selected value
SELECTED=$(eww -c "$EWW_CONFIG" get selected 2>/dev/null || echo 1)

case "$DIRECTION" in
    up)
        NEW_SELECTED=$((SELECTED - 1))
        [ $NEW_SELECTED -lt 0 ] && NEW_SELECTED=8
        ;;
    down)
        NEW_SELECTED=$((SELECTED + 1))
        [ $NEW_SELECTED -gt 8 ] && NEW_SELECTED=0
        ;;
    *)
        exit 1
        ;;
esac

eww -c "$EWW_CONFIG" update selected="$NEW_SELECTED"

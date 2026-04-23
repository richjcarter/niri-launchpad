#!/bin/bash
# Cycle to the next background video

BACKGROUNDS_DIR="$HOME/.local/share/launchpad/backgrounds"
STATE_FILE="/tmp/launchpad-bg-index"

# Get list of backgrounds
BACKGROUNDS=(
    "$BACKGROUNDS_DIR/nature_water.mp4"
    "$BACKGROUNDS_DIR/fireplace.mp4"
    "$BACKGROUNDS_DIR/rain_window.mp4"
    "$BACKGROUNDS_DIR/abstract.mp4"
    "$BACKGROUNDS_DIR/space_stars.mp4"
)

# Read current index
if [ -f "$STATE_FILE" ]; then
    INDEX=$(cat "$STATE_FILE")
else
    INDEX=0
fi

# Increment and wrap
INDEX=$(( (INDEX + 1) % ${#BACKGROUNDS[@]} ))
echo "$INDEX" > "$STATE_FILE"

# Get new background
NEW_BG="${BACKGROUNDS[$INDEX]}"

# Only apply if on Default workspace
CURRENT_WS=$(niri msg -j workspaces | jq -r '.[] | select(.is_focused == true) | .name // .idx')

if [ "$CURRENT_WS" = "Default" ] && [ -f "$NEW_BG" ]; then
    pkill mpvpaper 2>/dev/null
    sleep 0.2
    mpvpaper -o "loop no-audio" '*' "$NEW_BG" &
    notify-send "Launchpad" "Background: $(basename "$NEW_BG" .mp4)" -t 2000
fi

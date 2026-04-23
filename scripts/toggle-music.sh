#!/bin/bash
# Toggle launchpad ambient music on/off

MUSIC_DIR="$HOME/.local/share/launchpad/music"

# Check if music is playing
if pgrep -f "mpv.*launchpad-music" > /dev/null; then
    # Stop music
    pkill -f "mpv.*launchpad-music"
    notify-send "Launchpad" "Music paused" -t 2000
else
    # Start music (random track)
    MUSIC_FILES=(
        "$MUSIC_DIR/piano_ambient.mp3"
        "$MUSIC_DIR/classical_guitar.mp3"
    )
    RANDOM_MUSIC="${MUSIC_FILES[$RANDOM % ${#MUSIC_FILES[@]}]}"

    if [ -f "$RANDOM_MUSIC" ]; then
        mpv --no-video --loop --volume=30 --title="launchpad-music" "$RANDOM_MUSIC" &
        notify-send "Launchpad" "Playing: $(basename "$RANDOM_MUSIC" .mp3)" -t 2000
    fi
fi

#!/bin/bash
# Workspace Monitor for Launchpad
# Shows/hides launchpad components based on active workspace

LAUNCHPAD_DIR="$HOME/.local/share/launchpad"
EWW_CONFIG="$HOME/.config/eww/launchpad"
STATE_FILE="/tmp/launchpad-active"
VISITED_FILE="/tmp/launchpad-visited-workspaces"

get_current_workspace() {
    niri msg -j workspaces | jq -r '.[] | select(.is_focused == true) | .name // .idx'
}

get_workspace_index() {
    # Map workspace name to index (1-8)
    case "$1" in
        "Default") echo 1 ;;
        "Focus") echo 2 ;;
        "Admin") echo 3 ;;
        "Research") echo 4 ;;
        "Meetings") echo 5 ;;
        "Dev") echo 6 ;;
        "Demo") echo 7 ;;
        "Gaming") echo 8 ;;
        *) echo "$1" ;;  # Fallback to raw value
    esac
}

# Note: Workspace activation is now handled through the launcher confirmation flow
# in handle-input.sh, not automatically when switching workspaces

start_launchpad() {
    # Already active? Skip
    [ -f "$STATE_FILE" ] && return

    touch "$STATE_FILE"

    # Open EWW dashboard
    GTK_THEME=Adwaita:dark eww -c "$EWW_CONFIG" open launchpad
}

stop_launchpad() {
    # Not active? Skip
    [ ! -f "$STATE_FILE" ] && return

    rm -f "$STATE_FILE"

    # Close EWW dashboard
    eww -c "$EWW_CONFIG" close launchpad 2>/dev/null
}

# Cleanup on exit
cleanup() {
    stop_launchpad
    exit 0
}
trap cleanup SIGTERM SIGINT

# Initial state
LAST_WORKSPACE=""

# Main loop
while true; do
    CURRENT=$(get_current_workspace)

    if [ "$CURRENT" != "$LAST_WORKSPACE" ]; then
        if [ "$CURRENT" = "Default" ]; then
            start_launchpad
        else
            stop_launchpad
        fi
        LAST_WORKSPACE="$CURRENT"
    fi

    sleep 0.5
done

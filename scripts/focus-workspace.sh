#!/bin/bash
# Focus workspace with activation check
# If workspace is not activated, opens launcher with confirmation prompt
# Usage: focus-workspace.sh <workspace_number>

WS="$1"
EWW_CONFIG="$HOME/.config/eww/launchpad"
VISITED_FILE="/tmp/launchpad-visited-workspaces"

# Map workspace number to name
get_workspace_name() {
    case "$1" in
        1) echo "Default" ;;
        2) echo "Focus" ;;
        3) echo "Admin" ;;
        4) echo "Research" ;;
        5) echo "Meetings" ;;
        6) echo "Dev" ;;
        7) echo "Demo" ;;
        8) echo "Gaming" ;;
        *) echo "Default" ;;
    esac
}

# Check if workspace is activated
is_activated() {
    local ws="$1"
    # Workspace 0 (Launch All) and 1 (Default/Launchpad) are always activated
    if [ "$ws" = "0" ] || [ "$ws" = "1" ]; then
        return 0
    fi
    grep -q "^${ws}$" "$VISITED_FILE" 2>/dev/null
}

if is_activated "$WS"; then
    # Workspace is activated - focus directly using workspace name
    ws_name=$(get_workspace_name "$WS")
    niri msg action focus-workspace "$ws_name"
else
    # Workspace not activated - open launcher with confirmation prompt
    GTK_THEME=Adwaita:dark eww -c "$EWW_CONFIG" open launchpad

    # Set the selected workspace and show activation prompt
    eww -c "$EWW_CONFIG" update selected="$WS" error-msg="Press Enter to activate" pending-ws="$WS"
fi

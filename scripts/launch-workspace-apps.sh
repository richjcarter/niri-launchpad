#!/bin/bash
# Launch Workspace Apps - Spawns and positions configured apps for a workspace
# Usage: launch-workspace-apps.sh <workspace_number>
# Uses Niri native commands: spawn, move-column-to-index

WS="$1"
CONFIG_FILE="$HOME/.config/launchpad/workspace-layouts.json"

# Exit if no workspace specified
[ -z "$WS" ] && exit 0

# Map workspace number to name (Niri uses names, not numbers)
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

# Exit if config file doesn't exist
[ ! -f "$CONFIG_FILE" ] && exit 0

# Get apps for this workspace, sorted by position
apps=$(jq -r ".workspaces.\"$WS\".apps | sort_by(.position) | .[] | @base64" "$CONFIG_FILE" 2>/dev/null)

# Exit if no apps configured
[ -z "$apps" ] && exit 0

# Focus the target workspace first (using workspace name, not number)
WS_NAME=$(get_workspace_name "$WS")
niri msg action focus-workspace "$WS_NAME"
sleep 0.3

# Launch each app sequentially
position=0
for app_b64 in $apps; do
    # Decode app data
    app_json=$(echo "$app_b64" | base64 -d)
    exec_cmd=$(echo "$app_json" | jq -r '.exec')
    app_args=$(echo "$app_json" | jq -r '.args // ""')
    name=$(echo "$app_json" | jq -r '.name')

    [ -z "$exec_cmd" ] && continue

    # Build full command with args if present
    full_cmd="$exec_cmd"
    [ -n "$app_args" ] && full_cmd="$exec_cmd $app_args"

    # Launch app using Niri's native spawn
    niri msg action spawn -- $full_cmd &

    # Wait for window to appear
    sleep 1.2

    # Position using Niri's native move-column-to-index
    # This moves the focused column (the newly spawned app) to the correct position
    niri msg action move-column-to-index "$position"

    position=$((position + 1))

    # Small delay between apps
    sleep 0.3
done

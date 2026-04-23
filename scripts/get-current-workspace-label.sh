#!/bin/bash
# Get current workspace name for Noctalia bar display
# Outputs: "CURRENT: WORKSPACE_NAME"

WS_NAME=$(niri msg -j workspaces | jq -r '.[] | select(.is_focused == true) | .name // .idx')

# Map to display name if needed (handle unnamed workspaces)
case "$WS_NAME" in
    "") echo "CURRENT: -" ;;
    *) echo "CURRENT: ${WS_NAME^^}" ;;  # Uppercase the name
esac

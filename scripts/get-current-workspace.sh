#!/bin/bash
# Get current workspace index (1-8)

WS_NAME=$(niri msg -j workspaces | jq -r '.[] | select(.is_focused == true) | .name // .idx')

case "$WS_NAME" in
    "Default") echo 1 ;;
    "Focus") echo 2 ;;
    "Admin") echo 3 ;;
    "Research") echo 4 ;;
    "Meetings") echo 5 ;;
    "Dev") echo 6 ;;
    "Demo") echo 7 ;;
    "Gaming") echo 8 ;;
    *) echo "$WS_NAME" ;;
esac

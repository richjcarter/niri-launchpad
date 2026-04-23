#!/bin/bash
# Navigate only to activated (visited) workspaces with wrap-around
# Usage: navigate-activated.sh up|down

DIRECTION="$1"
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

# Get current workspace index
get_current_index() {
    local ws_name
    ws_name=$(niri msg -j workspaces | jq -r '.[] | select(.is_focused == true) | .name // .idx')

    case "$ws_name" in
        "Default") echo 1 ;;
        "Focus") echo 2 ;;
        "Admin") echo 3 ;;
        "Research") echo 4 ;;
        "Meetings") echo 5 ;;
        "Dev") echo 6 ;;
        "Demo") echo 7 ;;
        "Gaming") echo 8 ;;
        *) echo "$ws_name" ;;
    esac
}

# Get sorted list of visited workspaces (excluding 0 which is "Launch All")
get_visited_sorted() {
    if [ -f "$VISITED_FILE" ]; then
        grep -v '^0$' "$VISITED_FILE" 2>/dev/null | sort -n | uniq
    fi
}

CURRENT=$(get_current_index)
VISITED=($(get_visited_sorted))

# If no visited workspaces or only one, do nothing
if [ ${#VISITED[@]} -le 1 ]; then
    exit 0
fi

# Find current position in visited array
CURRENT_POS=-1
for i in "${!VISITED[@]}"; do
    if [ "${VISITED[$i]}" = "$CURRENT" ]; then
        CURRENT_POS=$i
        break
    fi
done

# If current workspace not in visited list, just go to first visited
if [ $CURRENT_POS -eq -1 ]; then
    ws_name=$(get_workspace_name "${VISITED[0]}")
    niri msg action focus-workspace "$ws_name"
    exit 0
fi

# Calculate next position with wrap-around
case "$DIRECTION" in
    up)
        NEW_POS=$(( (CURRENT_POS - 1 + ${#VISITED[@]}) % ${#VISITED[@]} ))
        ;;
    down)
        NEW_POS=$(( (CURRENT_POS + 1) % ${#VISITED[@]} ))
        ;;
    *)
        exit 1
        ;;
esac

# Focus the new workspace
ws_name=$(get_workspace_name "${VISITED[$NEW_POS]}")
niri msg action focus-workspace "$ws_name"

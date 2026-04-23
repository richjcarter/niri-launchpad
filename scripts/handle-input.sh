#!/bin/bash
# Handle input from the launchpad prompt
# Supports: 0-8 (workspace selection), Enter (launch with confirmation for unactivated)
# Navigation via MOD+SHIFT+Up/Down arrows

INPUT="$1"
EVENT="$2"  # "change" or "accept"
EWW_CONFIG="$HOME/.config/eww/launchpad"
VISITED_FILE="/tmp/launchpad-visited-workspaces"

# Get current selected value
SELECTED=$(eww -c "$EWW_CONFIG" get selected 2>/dev/null || echo 1)

# Get pending workspace (for confirmation flow)
PENDING=$(eww -c "$EWW_CONFIG" get pending-ws 2>/dev/null || echo "")

# Check if a workspace is activated (visited)
is_activated() {
    local ws="$1"
    # Workspace 0 (Launch All) and 1 (Default/Launchpad) are always activated
    if [ "$ws" = "0" ] || [ "$ws" = "1" ]; then
        return 0
    fi
    grep -q "^${ws}$" "$VISITED_FILE" 2>/dev/null
}

# Mark workspace as activated
activate_workspace() {
    local ws="$1"
    if ! grep -q "^${ws}$" "$VISITED_FILE" 2>/dev/null; then
        echo "$ws" >> "$VISITED_FILE"
    fi
}

# Clear messages
clear_messages() {
    eww -c "$EWW_CONFIG" update error-msg="" pending-ws=""
}

# Show error message
show_error() {
    eww -c "$EWW_CONFIG" update error-msg="computer says no. try again." pending-ws=""
    # Clear error after 3 seconds
    (sleep 3 && eww -c "$EWW_CONFIG" update error-msg="" 2>/dev/null) &
}

# Show activation prompt
show_activation_prompt() {
    local ws="$1"
    eww -c "$EWW_CONFIG" update error-msg="Press Enter again to activate" pending-ws="$ws"
}

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

# Focus a workspace and close launchpad
focus_workspace() {
    local ws="$1"
    local ws_name
    ws_name=$(get_workspace_name "$ws")
    niri msg action focus-workspace "$ws_name"
    clear_messages
    # Close launchpad if not going to Launchpad workspace
    if [ "$ws" != "1" ]; then
        eww -c "$EWW_CONFIG" close launchpad 2>/dev/null
    fi
}

# Activate all workspaces (Launch All - option 0)
launch_all() {
    # Activate workspaces 2-8 (1 is always activated)
    for ws in 2 3 4 5 6 7 8; do
        activate_workspace "$ws"
    done
    clear_messages
    eww -c "$EWW_CONFIG" update error-msg="All workspaces activated!"
    # Clear message after 2 seconds
    (sleep 2 && eww -c "$EWW_CONFIG" update error-msg="" 2>/dev/null) &
}

# Handle Enter key (accept event)
if [ "$EVENT" = "accept" ]; then
    # Check for "configure" command
    if [ "$INPUT" = "configure" ] || [ "$INPUT" = "config" ] || [ "$INPUT" = "c" ]; then
        ~/.local/share/launchpad/scripts/configure-handler.sh enter
        exit 0
    fi

    # Determine which workspace to act on
    if [[ "$INPUT" =~ ^[0-8]$ ]]; then
        TARGET="$INPUT"
    elif [ -z "$INPUT" ]; then
        TARGET="$SELECTED"
    else
        show_error
        exit 0
    fi

    # Handle "Launch All" (option 0)
    if [ "$TARGET" = "0" ]; then
        launch_all
        exit 0
    fi

    # Check if we're confirming a pending activation
    if [ "$PENDING" = "$TARGET" ]; then
        # Second Enter - activate and switch
        activate_workspace "$TARGET"
        focus_workspace "$TARGET"
        # Launch configured apps for this workspace
        ~/.local/share/launchpad/scripts/launch-workspace-apps.sh "$TARGET" &
        exit 0
    fi

    # Check if workspace is already activated
    if is_activated "$TARGET"; then
        # Already activated - just switch
        focus_workspace "$TARGET"
    else
        # Not activated - show confirmation prompt
        show_activation_prompt "$TARGET"
    fi
    exit 0
fi

# Handle input changes - just update selection if it's a number
LAST_CHAR="${INPUT: -1}"
if [[ "$LAST_CHAR" =~ ^[0-8]$ ]]; then
    # Clear pending state when changing selection
    eww -c "$EWW_CONFIG" update selected="$LAST_CHAR" error-msg="" pending-ws=""
fi

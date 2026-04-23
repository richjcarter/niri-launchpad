#!/bin/bash
# Handle Enter/confirm in launcher and configure modes
# Usage: configure-confirm.sh

EWW_CONFIG="$HOME/.config/eww/launchpad"

# Check if configure window is open
if eww -c "$EWW_CONFIG" active-windows 2>/dev/null | grep -q "configure"; then
    MODE=$(eww -c "$EWW_CONFIG" get cfg-mode 2>/dev/null)
    SELECTED=$(eww -c "$EWW_CONFIG" get cfg-selected 2>/dev/null)

    case "$MODE" in
        "ws-select")
            # Select the highlighted workspace
            ~/.local/share/launchpad/scripts/configure-handler.sh select-ws "$SELECTED"
            ;;
        "app-list")
            # Open app picker to add an app
            ~/.local/share/launchpad/scripts/configure-handler.sh input "add" accept
            ;;
        "app-picker")
            # Pick the selected app
            ~/.local/share/launchpad/scripts/configure-handler.sh pick-app
            ;;
    esac
    exit 0
fi

# Check if launchpad is open - handle it
if eww -c "$EWW_CONFIG" active-windows 2>/dev/null | grep -q "launchpad"; then
    ~/.local/share/launchpad/scripts/handle-input.sh "" accept
    exit 0
fi

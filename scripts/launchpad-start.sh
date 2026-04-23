#!/bin/bash
# Launchpad Workspace Startup Script
# Starts the workspace monitor that handles animated wallpaper and EWW dashboard

LAUNCHPAD_DIR="$HOME/.local/share/launchpad"
SCRIPTS_DIR="$LAUNCHPAD_DIR/scripts"

# ─────────────────────────────────────────────────────────────
# Stop any existing instances
# ─────────────────────────────────────────────────────────────
pkill -f "workspace-monitor.sh" 2>/dev/null
pkill -f "mpv.*launchpad-music" 2>/dev/null
eww -c "$HOME/.config/eww/launchpad" kill 2>/dev/null
rm -f /tmp/launchpad-active

# Initialize visited workspaces - workspace 1 (Default) is always activated
echo "1" > /tmp/launchpad-visited-workspaces

# ─────────────────────────────────────────────────────────────
# Start workspace monitor (handles wallpaper + EWW per workspace)
# ─────────────────────────────────────────────────────────────
"$SCRIPTS_DIR/workspace-monitor.sh" &

echo "Launchpad monitor started!"

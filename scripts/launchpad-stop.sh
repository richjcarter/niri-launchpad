#!/bin/bash
# Launchpad Workspace Stop Script
# Stops all launchpad components

EWW_CONFIG="$HOME/.config/eww/launchpad"

# Stop workspace monitor
pkill -f "workspace-monitor.sh" 2>/dev/null

# Stop EWW dashboard
eww -c "$EWW_CONFIG" close launchpad 2>/dev/null

# Stop music
pkill -f "mpv.*launchpad-music" 2>/dev/null

# Stop animated wallpaper
pkill mpvpaper 2>/dev/null

# Remove state file
rm -f /tmp/launchpad-active

# Restore static wallpaper
swww img /usr/share/wallpapers/cachyos-wallpapers/Skyscraper.png 2>/dev/null

echo "Launchpad stopped!"

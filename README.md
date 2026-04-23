# Niri Launchpad

A workspace launcher and management system for the [Niri](https://github.com/YaLTeR/niri) Wayland compositor, built with [EWW](https://github.com/elkowar/eww) widgets.

![Niri Launchpad Screenshot](screenshot.png)

## Features

- **8 Named Workspaces**: Default, Focus, Admin, Research, Meetings, Dev, Demo, Gaming
- **Workspace Activation**: Workspaces must be "activated" before use (prevents accidental navigation)
- **App Configuration**: Set up apps to auto-launch when a workspace is first activated
- **Custom Launch Arguments**: Configure apps with specific URLs, directories, or flags
- **Ambient Features**: Animated wallpapers and background music (optional)

## Dependencies

- [Niri](https://github.com/YaLTeR/niri) - Wayland compositor
- [EWW](https://github.com/elkowar/eww) - Widget system (use `eww-git` for best Wayland support)
- [wofi](https://hg.sr.ht/~scoopta/wofi) - App picker
- [jq](https://jqlang.github.io/jq/) - JSON processing
- [mpvpaper](https://github.com/GhostNaN/mpvpaper) - Animated wallpapers (optional)
- [mpv](https://mpv.io/) - Background music (optional)

## Installation

### 1. Clone the repository

```bash
git clone https://github.com/richjcarter/niri-launchpad.git
cd niri-launchpad
```

### 2. Copy files to their locations

```bash
# EWW widgets
mkdir -p ~/.config/eww/launchpad
cp eww/* ~/.config/eww/launchpad/

# Scripts
mkdir -p ~/.local/share/launchpad/scripts
cp scripts/* ~/.local/share/launchpad/scripts/
chmod +x ~/.local/share/launchpad/scripts/*.sh

# Config directory
mkdir -p ~/.config/launchpad
cp config/workspace-layouts.example.json ~/.config/launchpad/workspace-layouts.json
```

### 3. Add keybindings to Niri config

Add the workspace definitions and keybindings from `config/niri-keybindings.example.kdl` to your `~/.config/niri/config.kdl`.

### 4. Start the launcher

```bash
~/.local/share/launchpad/scripts/launchpad-start.sh
```

Or add to your Niri startup:
```kdl
spawn-sh-at-startup "sleep 2 && ~/.local/share/launchpad/scripts/launchpad-start.sh"
```

## Keybindings

### Launcher
| Keybinding | Action |
|------------|--------|
| `MOD+\` | Toggle launcher window |
| `MOD+GRAVE` | Jump to Default workspace |
| `MOD+1-8` | Focus workspace (opens launcher if not activated) |
| `MOD+UP/DOWN` | Navigate between activated workspaces |

### Launcher Navigation
| Keybinding | Action |
|------------|--------|
| `MOD+SHIFT+↑/↓` | Navigate menu |
| `MOD+SHIFT+Return` | Confirm/select |
| `MOD+Backspace` | Go back |

### Configure Mode
Type "configure" (or "config" or "c") in the launcher to enter configure mode.

| Keybinding | Action |
|------------|--------|
| `MOD+SHIFT+↑/↓` | Navigate app list |
| `MOD+SHIFT+←/→` | Reorder apps |
| `MOD+SHIFT+A` | Add app (opens wofi picker) |
| `MOD+SHIFT+E` | Edit app launch arguments |
| `MOD+SHIFT+X` | Remove selected app |
| `MOD+Backspace` | Go back / exit configure |

## Configuration

### Workspace Layouts

Apps are configured per-workspace in `~/.config/launchpad/workspace-layouts.json`:

```json
{
  "version": 1,
  "workspaces": {
    "3": {
      "name": "Admin",
      "apps": [
        {
          "desktop_file": "kitty.desktop",
          "name": "Kitty",
          "exec": "kitty",
          "args": "--directory ~/projects/sys-admin",
          "position": 0
        }
      ]
    }
  }
}
```

### Custom Launch Arguments Examples

- **Firefox with URL**: `https://mail.google.com`
- **Kitty with directory**: `--directory ~/projects/myproject`
- **VS Code with folder**: `~/projects/myproject`

## Optional: Ambient Features

### Animated Wallpapers

Place video files in `~/.local/share/launchpad/backgrounds/` and use `MOD+SHIFT+B` to cycle through them.

### Background Music

Place music files in `~/.local/share/launchpad/music/` and use `MOD+SHIFT+M` to toggle playback.

## File Structure

```
~/.config/eww/launchpad/
├── eww.yuck          # Main launcher widget
├── eww.scss          # Launcher styles
├── configure.yuck    # Configure mode widget
└── configure.scss    # Configure mode styles

~/.local/share/launchpad/scripts/
├── launchpad-start.sh        # Start workspace monitor
├── launchpad-stop.sh         # Stop all components
├── workspace-monitor.sh      # Auto-shows/hides launchpad
├── handle-input.sh           # Main input handler
├── navigate.sh               # Launcher navigation
├── navigate-activated.sh     # Workspace navigation
├── focus-workspace.sh        # MOD+1-8 handler
├── configure-handler.sh      # Configure mode logic
├── configure-confirm.sh      # Confirm keybind handler
├── launch-workspace-apps.sh  # App launcher on activation
├── search-apps.sh            # App search
├── get-current-workspace.sh  # Current workspace index
├── get-current-workspace-label.sh  # For status bars
├── cycle-background.sh       # Cycle wallpapers
└── toggle-music.sh           # Toggle ambient music

~/.config/launchpad/
└── workspace-layouts.json    # App configurations
```

## License

MIT

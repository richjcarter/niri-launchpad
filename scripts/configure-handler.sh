#!/bin/bash
# Configure Handler - Central script for all configure mode operations
# Usage: configure-handler.sh <command> [args...]

COMMAND="$1"
shift

EWW_CONFIG="$HOME/.config/eww/launchpad"
CONFIG_FILE="$HOME/.config/launchpad/workspace-layouts.json"

# Ensure config file exists
[ ! -f "$CONFIG_FILE" ] && echo '{"version":1,"workspaces":{"2":{"name":"Focus","apps":[]},"3":{"name":"Admin","apps":[]},"4":{"name":"Research","apps":[]},"5":{"name":"Meetings","apps":[]},"6":{"name":"Dev","apps":[]},"7":{"name":"Demo","apps":[]},"8":{"name":"Gaming","apps":[]}}}' > "$CONFIG_FILE"

# ─────────────────────────────────────────────────────────────
# Helper Functions
# ─────────────────────────────────────────────────────────────

update_eww() {
    eww -c "$EWW_CONFIG" update "$@" 2>/dev/null
}

get_eww() {
    eww -c "$EWW_CONFIG" get "$1" 2>/dev/null
}

show_msg() {
    update_eww cfg-msg="$1"
    # Clear after 3 seconds
    (sleep 3 && update_eww cfg-msg="" 2>/dev/null) &
}

get_app_count() {
    jq -r ".workspaces.\"$1\".apps | length" "$CONFIG_FILE" 2>/dev/null || echo 0
}

# ─────────────────────────────────────────────────────────────
# Enter Configure Mode
# ─────────────────────────────────────────────────────────────

enter_configure() {
    # Close launchpad, open configure window
    eww -c "$EWW_CONFIG" close launchpad 2>/dev/null
    update_eww cfg-mode="ws-select" cfg-selected=2 cfg-ws="" cfg-search="" cfg-msg=""
    GTK_THEME=Adwaita:dark eww -c "$EWW_CONFIG" open configure
}

# ─────────────────────────────────────────────────────────────
# Exit Configure Mode
# ─────────────────────────────────────────────────────────────

exit_configure() {
    eww -c "$EWW_CONFIG" close configure 2>/dev/null
    update_eww cfg-mode="" cfg-ws="" cfg-search="" cfg-msg=""
    # Optionally reopen launchpad
    GTK_THEME=Adwaita:dark eww -c "$EWW_CONFIG" open launchpad
}

# ─────────────────────────────────────────────────────────────
# Screen Navigation
# ─────────────────────────────────────────────────────────────

go_back() {
    local mode
    mode=$(get_eww cfg-mode)
    case "$mode" in
        "ws-select")
            exit_configure
            ;;
        "app-list")
            update_eww cfg-mode="ws-select" cfg-ws="" cfg-selected=2 cfg-msg=""
            ;;
        "app-picker")
            update_eww cfg-mode="app-list" cfg-search="" cfg-selected=0 cfg-msg=""
            ;;
    esac
}

# ─────────────────────────────────────────────────────────────
# Workspace Selection
# ─────────────────────────────────────────────────────────────

select_workspace() {
    local ws="$1"
    if [[ "$ws" =~ ^[2-8]$ ]]; then
        update_eww cfg-ws="$ws" cfg-mode="app-list" cfg-selected=0 cfg-msg=""
    else
        show_msg "Invalid workspace (2-8)"
    fi
}

# ─────────────────────────────────────────────────────────────
# App List Operations
# ─────────────────────────────────────────────────────────────

open_app_picker() {
    # Use wofi for app selection - doesn't steal focus from other windows
    local ws
    ws=$(get_eww cfg-ws)

    # Build list of apps from .desktop files
    local apps=""
    for dir in /usr/share/applications ~/.local/share/applications; do
        [ -d "$dir" ] || continue
        for file in "$dir"/*.desktop; do
            [ -f "$file" ] || continue
            # Skip NoDisplay apps
            grep -q "^NoDisplay=true" "$file" && continue
            local name
            name=$(grep -m1 "^Name=" "$file" | cut -d= -f2)
            [ -n "$name" ] && apps+="$name|$(basename "$file")"$'\n'
        done
    done

    # Sort and remove duplicates, then show in wofi
    # --layer top ensures wofi appears above other windows
    # User presses Enter to select, Escape to cancel (wofi closes automatically)
    local selection
    selection=$(echo -e "$apps" | sort -u | cut -d'|' -f1 | wofi --show dmenu --prompt "Add app (Enter=select, Esc=cancel)" --insensitive --layer top 2>/dev/null)

    if [ -n "$selection" ]; then
        # Find the .desktop file for the selected app
        local desktop_file
        desktop_file=$(echo -e "$apps" | grep "^${selection}|" | head -1 | cut -d'|' -f2)
        if [ -n "$desktop_file" ]; then
            add_app "$desktop_file"
        else
            show_msg "App not found"
        fi
    fi
}

remove_app() {
    local ws index
    ws=$(get_eww cfg-ws)
    index="$1"

    if [ -z "$index" ]; then
        index=$(get_eww cfg-selected)
    fi

    local count
    count=$(get_app_count "$ws")

    if [ "$count" -eq 0 ]; then
        show_msg "No apps to remove"
        return
    fi

    if [ "$index" -ge "$count" ]; then
        show_msg "Invalid selection"
        return
    fi

    # Remove app at index and reorder positions
    local tmp
    tmp=$(mktemp)
    jq ".workspaces.\"$ws\".apps |= (del(.[$index]) | to_entries | map(.value.position = .key) | map(.value))" "$CONFIG_FILE" > "$tmp" && mv "$tmp" "$CONFIG_FILE"

    show_msg "App removed"
}

edit_app_args() {
    local ws index
    ws=$(get_eww cfg-ws)
    index=$(get_eww cfg-selected)

    local count
    count=$(get_app_count "$ws")

    if [ "$count" -eq 0 ]; then
        show_msg "No apps to edit"
        return
    fi

    if [ "$index" -ge "$count" ]; then
        show_msg "Invalid selection"
        return
    fi

    # Get current app info
    local app_name current_args
    app_name=$(jq -r ".workspaces.\"$ws\".apps[$index].name" "$CONFIG_FILE")
    current_args=$(jq -r ".workspaces.\"$ws\".apps[$index].args // \"\"" "$CONFIG_FILE")

    # Use wofi to prompt for arguments
    # Pre-fill with current args if any
    local new_args
    new_args=$(echo "$current_args" | wofi --show dmenu --prompt "$app_name args (URL, --dir, etc.)" --lines 1 --layer top 2>/dev/null)

    # If user cancelled (Esc), wofi returns empty and exit code != 0
    if [ $? -eq 0 ]; then
        # Update args in config
        local tmp
        tmp=$(mktemp)
        jq --argjson i "$index" --arg args "$new_args" '
            .workspaces."'"$ws"'".apps[$i].args = $args
        ' "$CONFIG_FILE" > "$tmp" && mv "$tmp" "$CONFIG_FILE"

        if [ -n "$new_args" ]; then
            show_msg "Args: $new_args"
        else
            show_msg "Args cleared"
        fi
    fi
}

reorder_app() {
    local direction="$1"  # "left" or "right"
    local ws index count
    ws=$(get_eww cfg-ws)
    index=$(get_eww cfg-selected)
    count=$(get_app_count "$ws")

    if [ "$count" -lt 2 ]; then
        show_msg "Need 2+ apps to reorder"
        return
    fi

    local target
    if [ "$direction" = "left" ]; then
        if [ "$index" -eq 0 ]; then
            show_msg "Already at start"
            return
        fi
        target=$((index - 1))
    else
        if [ "$index" -ge $((count - 1)) ]; then
            show_msg "Already at end"
            return
        fi
        target=$((index + 1))
    fi

    # Swap apps at index and target
    local tmp
    tmp=$(mktemp)
    jq --argjson i "$index" --argjson t "$target" '
        .workspaces."'"$ws"'".apps |= (
            .[$i].position = $t |
            .[$t].position = $i |
            sort_by(.position)
        )
    ' "$CONFIG_FILE" > "$tmp" && mv "$tmp" "$CONFIG_FILE"

    update_eww cfg-selected="$target"
    show_msg "Moved ${direction}"
}

# ─────────────────────────────────────────────────────────────
# App Picker Operations
# ─────────────────────────────────────────────────────────────

update_search() {
    local query="$1"
    update_eww cfg-search="$query" cfg-selected=0
    # Update search results file for EWW poll
    ~/.local/share/launchpad/scripts/search-apps.sh "$query" > /tmp/launchpad-search-results.json
}

add_app() {
    local desktop_file="$1"
    local ws
    ws=$(get_eww cfg-ws)

    # Get app details from .desktop file
    local file_path=""
    for dir in /usr/share/applications ~/.local/share/applications; do
        if [ -f "$dir/$desktop_file" ]; then
            file_path="$dir/$desktop_file"
            break
        fi
    done

    if [ -z "$file_path" ]; then
        show_msg "App not found"
        return
    fi

    local name exec_cmd
    name=$(grep -m1 "^Name=" "$file_path" | cut -d= -f2)
    exec_cmd=$(grep -m1 "^Exec=" "$file_path" | cut -d= -f2 | sed 's/ %[fFuUdDnNickvm]//g')

    if [ -z "$name" ] || [ -z "$exec_cmd" ]; then
        show_msg "Invalid desktop file"
        return
    fi

    # Check if already added
    if jq -e ".workspaces.\"$ws\".apps[] | select(.desktop_file == \"$desktop_file\")" "$CONFIG_FILE" >/dev/null 2>&1; then
        show_msg "Already added"
        return
    fi

    # Get next position
    local position
    position=$(get_app_count "$ws")

    # Add app to config (with empty args field for custom launch arguments)
    local tmp
    tmp=$(mktemp)
    jq --arg df "$desktop_file" --arg n "$name" --arg e "$exec_cmd" --argjson p "$position" '
        .workspaces."'"$ws"'".apps += [{
            "desktop_file": $df,
            "name": $n,
            "exec": $e,
            "args": "",
            "position": $p
        }]
    ' "$CONFIG_FILE" > "$tmp" && mv "$tmp" "$CONFIG_FILE"

    show_msg "Added: $name"
    update_eww cfg-mode="app-list" cfg-search="" cfg-selected="$position"
}

pick_selected_app() {
    local selected desktop_file
    selected=$(get_eww cfg-selected)

    # Read from search results file
    desktop_file=$(jq -r ".[$selected].file // empty" /tmp/launchpad-search-results.json 2>/dev/null)

    if [ -n "$desktop_file" ] && [ "$desktop_file" != "null" ]; then
        add_app "$desktop_file"
    else
        show_msg "No app selected"
    fi
}

# ─────────────────────────────────────────────────────────────
# Input Handler
# ─────────────────────────────────────────────────────────────

handle_input() {
    local input="$1"
    local event="$2"
    local mode
    mode=$(get_eww cfg-mode)

    case "$mode" in
        "ws-select")
            if [ "$event" = "accept" ]; then
                if [[ "$input" =~ ^[2-8]$ ]]; then
                    select_workspace "$input"
                elif [ -z "$input" ]; then
                    select_workspace "$(get_eww cfg-selected)"
                elif [ "$input" = "q" ] || [ "$input" = "esc" ]; then
                    exit_configure
                else
                    show_msg "Type 2-8 or ESC"
                fi
            fi
            ;;
        "app-list")
            if [ "$event" = "accept" ]; then
                if [ "$input" = "add" ] || [ "$input" = "a" ]; then
                    open_app_picker
                elif [[ "$input" =~ ^del\ ?([0-9]+)?$ ]]; then
                    local idx="${BASH_REMATCH[1]}"
                    if [ -n "$idx" ]; then
                        remove_app "$((idx - 1))"
                    else
                        remove_app
                    fi
                elif [ "$input" = "q" ] || [ "$input" = "esc" ] || [ "$input" = "back" ]; then
                    go_back
                elif [ -z "$input" ]; then
                    # Empty enter does nothing
                    :
                else
                    show_msg "Commands: add, del [N], esc"
                fi
            fi
            ;;
        "app-picker")
            if [ "$event" = "accept" ]; then
                if [ "$input" = "q" ] || [ "$input" = "esc" ] || [ "$input" = "back" ]; then
                    go_back
                else
                    pick_selected_app
                fi
            elif [ "$event" = "change" ]; then
                update_search "$input"
            fi
            ;;
    esac
}

# ─────────────────────────────────────────────────────────────
# Navigation (arrow keys via keybindings)
# ─────────────────────────────────────────────────────────────

navigate() {
    local direction="$1"  # "up", "down", "left", "right"
    local mode selected
    mode=$(get_eww cfg-mode)
    selected=$(get_eww cfg-selected)

    update_eww cfg-kbd-nav=true
    # Reset kbd-nav after timeout
    pkill -f "cfg-kbd-reset" 2>/dev/null
    (exec -a "cfg-kbd-reset" sleep 2; update_eww cfg-kbd-nav=false) &

    case "$mode" in
        "ws-select")
            case "$direction" in
                "up")
                    [ "$selected" -gt 2 ] && update_eww cfg-selected="$((selected - 1))"
                    ;;
                "down")
                    [ "$selected" -lt 8 ] && update_eww cfg-selected="$((selected + 1))"
                    ;;
            esac
            ;;
        "app-list")
            local count
            count=$(get_app_count "$(get_eww cfg-ws)")
            case "$direction" in
                "up")
                    [ "$selected" -gt 0 ] && update_eww cfg-selected="$((selected - 1))"
                    ;;
                "down")
                    [ "$selected" -lt $((count - 1)) ] && update_eww cfg-selected="$((selected + 1))"
                    ;;
                "left")
                    reorder_app "left"
                    ;;
                "right")
                    reorder_app "right"
                    ;;
            esac
            ;;
        "app-picker")
            local results_count
            results_count=$(jq 'length' /tmp/launchpad-search-results.json 2>/dev/null || echo 0)
            case "$direction" in
                "up")
                    [ "$selected" -gt 0 ] && update_eww cfg-selected="$((selected - 1))"
                    ;;
                "down")
                    [ "$selected" -lt $((results_count - 1)) ] && update_eww cfg-selected="$((selected + 1))"
                    ;;
            esac
            ;;
    esac
}

# ─────────────────────────────────────────────────────────────
# Command Dispatch
# ─────────────────────────────────────────────────────────────

case "$COMMAND" in
    "enter")
        enter_configure
        ;;
    "exit")
        exit_configure
        ;;
    "back")
        go_back
        ;;
    "select-ws")
        select_workspace "$1"
        ;;
    "select-app")
        update_eww cfg-selected="$1"
        ;;
    "add-app")
        add_app "$1"
        ;;
    "add-app-picker")
        # Only works in app-list mode
        if [ "$(get_eww cfg-mode)" = "app-list" ]; then
            open_app_picker
        fi
        ;;
    "remove-app")
        remove_app "$1"
        ;;
    "remove-selected")
        # Only works in app-list mode
        if [ "$(get_eww cfg-mode)" = "app-list" ]; then
            remove_app
        fi
        ;;
    "edit-args")
        # Only works in app-list mode
        if [ "$(get_eww cfg-mode)" = "app-list" ]; then
            edit_app_args
        fi
        ;;
    "search")
        update_search "$1"
        ;;
    "pick-app")
        pick_selected_app
        ;;
    "input")
        handle_input "$1" "$2"
        ;;
    "navigate")
        navigate "$1"
        ;;
    *)
        echo "Unknown command: $COMMAND" >&2
        exit 1
        ;;
esac

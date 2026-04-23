#!/bin/bash
# Search .desktop files and output JSON array for EWW
# Usage: search-apps.sh "query"

QUERY="$1"

# If no query, return empty array
if [ -z "$QUERY" ]; then
    echo "[]"
    exit 0
fi

# Search both system and user applications
results=""
count=0
max_results=10

for dir in /usr/share/applications ~/.local/share/applications; do
    [ ! -d "$dir" ] && continue

    for file in "$dir"/*.desktop; do
        [ ! -f "$file" ] && continue
        [ $count -ge $max_results ] && break 2

        # Skip NoDisplay entries
        grep -q "^NoDisplay=true" "$file" && continue

        # Get Name (first occurrence, not localized)
        name=$(grep -m1 "^Name=" "$file" | cut -d= -f2)
        [ -z "$name" ] && continue

        # Case-insensitive fuzzy match on name
        if echo "$name" | grep -qi "$QUERY"; then
            # Get Exec and strip format codes
            exec_cmd=$(grep -m1 "^Exec=" "$file" | cut -d= -f2 | sed 's/ %[fFuUdDnNickvm]//g')
            [ -z "$exec_cmd" ] && continue

            # Get basename for reference
            basename=$(basename "$file")

            # Escape quotes in name and exec for JSON
            name_escaped=$(echo "$name" | sed 's/"/\\"/g')
            exec_escaped=$(echo "$exec_cmd" | sed 's/"/\\"/g')

            # Build JSON object
            if [ -n "$results" ]; then
                results="$results,"
            fi
            results="$results{\"file\":\"$basename\",\"name\":\"$name_escaped\",\"exec\":\"$exec_escaped\"}"
            count=$((count + 1))
        fi
    done
done

echo "[$results]"

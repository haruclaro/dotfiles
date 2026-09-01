#!/bin/bash
# ~/.config/quickshell/scripts/peripherals.sh

output="["
first=true

for dev in $(upower -e | grep -v -E 'line_power|DisplayDevice|BAT'); do
    percent=$(upower -i "$dev" | awk '/percentage:/ {print $2}' | tr -d '%')
    model=$(upower -i "$dev" | awk -F': +' '/model:/ {print $2}' | tr -d '"')

    if [[ -n "$percent" ]]; then
        if [ "$first" = true ]; then
            first=false
        else
            output+=","
        fi
        if [[ -z "$model" ]]; then
            model="Dispositivo s/ fio"
        fi
        output+="{\"model\": \"$model\", \"percent\": $percent}"
    fi
done

output+="]"
echo "$output"

#!/bin/bash

# Increment/decrement by this much
STEP="2%"

if [ "$1" == "up" ]; then
    wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ $STEP+
elif [ "$1" == "down" ]; then
    wpctl set-volume @DEFAULT_AUDIO_SINK@ $STEP-
elif [ "$1" == "mute" ]; then
    wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
fi

# Get current volume
VOLUME_INFO=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)

if echo "$VOLUME_INFO" | grep -q "MUTED"; then
    notify-send -r 2593 -a "Volume" -u low -i audio-volume-muted "Mutado" "0%" -h int:value:0
else
    # Parse volume (e.g. "Volume: 0.75" -> 75)
    VOLUME_PERCENT=$(echo "$VOLUME_INFO" | awk '{print int($2 * 100)}')

    ICON="audio-volume-high"
    if [ "$VOLUME_PERCENT" -eq 0 ]; then
        ICON="audio-volume-muted"
    elif [ "$VOLUME_PERCENT" -le 30 ]; then
        ICON="audio-volume-low"
    elif [ "$VOLUME_PERCENT" -le 70 ]; then
        ICON="audio-volume-medium"
    fi

    notify-send -r 2593 -a "Volume" -u low -i "$ICON" "Volume" "${VOLUME_PERCENT}%" -h int:value:"$VOLUME_PERCENT"
fi

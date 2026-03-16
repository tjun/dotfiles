#!/usr/bin/env bash

source "$HOME/.config/sketchybar/variables.sh" # Loads all defined colors

SPACE_ICONS=("1" "2" "3" "4" "5" "6" "7" "8" "9" "10")

# macOS key codes for 1-9 keys (not sequential)
KEY_CODES=(18 19 20 21 23 22 26 28 25)
SPACE_CLICK_SCRIPT="osascript -e 'tell application \"System Events\" to key code ${KEY_CODES[$((SID - 1))]} using control down'"

if [ "$SELECTED" = "true" ]; then
	sketchybar --animate tanh 5 --set "$NAME" \
		icon.color="$RED" \
		icon="${SPACE_ICONS[$SID - 1]}" \
		click_script="$SPACE_CLICK_SCRIPT"
else
	sketchybar --animate tanh 5 --set "$NAME" \
		icon.color="$COMMENT" \
		icon="${SPACE_ICONS[$SID - 1]}" \
		click_script="$SPACE_CLICK_SCRIPT"
fi

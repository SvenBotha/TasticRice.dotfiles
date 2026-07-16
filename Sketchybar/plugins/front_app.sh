#!/usr/bin/env bash
# Shows the name of the frontmost application.
# $INFO is provided by Sketchybar on the front_app_switched event.

if [[ "$SENDER" == "front_app_switched" ]]; then
  sketchybar --set "$NAME" label="$INFO"
fi

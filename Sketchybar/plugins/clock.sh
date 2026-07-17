#!/usr/bin/env bash
# Simple date/time label, refreshed on the item's update_freq.

sketchybar --set "$NAME" label="$(date '+%a %d %b  %H:%M')"

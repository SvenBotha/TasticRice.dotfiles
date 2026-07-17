#!/usr/bin/env bash
# =============================================================================
#  Highlight the currently focused AeroSpace workspace in Sketchybar.
# =============================================================================
# Called two ways, both handled safely:
#   1. Directly by AeroSpace via exec-on-workspace-change in aerospace.toml.
#   2. As the `script` for each space.N item (on aerospace_workspace_change).
# It queries AeroSpace itself rather than relying on env vars, so it produces
# the correct state no matter how it was invoked.

FOCUSED="${FOCUSED_WORKSPACE:-$(aerospace list-workspaces --focused 2>/dev/null)}"

for sid in 1 2 3 4 5 6 7 8 9 10; do
  if [[ "$sid" == "$FOCUSED" ]]; then
    sketchybar --set space.$sid \
      background.drawing=on \
      icon.color=0xff47ff9c
  else
    sketchybar --set space.$sid \
      background.drawing=off \
      icon.color=0xffcbe0f0
  fi
done

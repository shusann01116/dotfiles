#!/bin/bash
# Focus a standard window on the target display, bypassing display --focus entirely.
# Usage: focus_display.sh <direction_or_number>
#   direction: east, west, north, south, prev
#   number:    1, 2, 3, 4
TARGET=$1

# Get current display info
cur=$(yabai -m query --displays --display | jq '{index, x: .frame.x, y: .frame.y, w: .frame.w, h: .frame.h}')
cur_idx=$(echo "$cur" | jq '.index')
cur_x=$(echo "$cur" | jq '.x')
cur_y=$(echo "$cur" | jq '.y')
cur_w=$(echo "$cur" | jq '.w')
cur_h=$(echo "$cur" | jq '.h')

# Resolve target display index
case "$TARGET" in
  [0-9]*)
    target_idx="$TARGET"
    ;;
  prev)
    # Find previous display (lower index)
    target_idx=$(yabai -m query --displays | jq --argjson c "$cur_idx" '[.[] | select(.index < $c)] | sort_by(.index) | last | .index // empty')
    ;;
  east)
    # Find the closest display to the right (higher x)
    cur_right=$(echo "$cur_x + $cur_w" | bc)
    target_idx=$(yabai -m query --displays | jq --argjson cx "$cur_right" --argjson ci "$cur_idx" \
      '[.[] | select(.index != $ci and .frame.x >= ($cx - 1))] | sort_by(.frame.x) | first | .index // empty')
    ;;
  west)
    # Find the closest display to the left (lower x)
    target_idx=$(yabai -m query --displays | jq --argjson cx "$cur_x" --argjson ci "$cur_idx" \
      '[.[] | select(.index != $ci and (.frame.x + .frame.w) <= ($cx + 1))] | sort_by(-.frame.x) | first | .index // empty')
    ;;
  north)
    # Find the closest display above (lower y)
    target_idx=$(yabai -m query --displays | jq --argjson cy "$cur_y" --argjson ci "$cur_idx" \
      '[.[] | select(.index != $ci and (.frame.y + .frame.h) <= ($cy + 1))] | sort_by(-.frame.y) | first | .index // empty')
    ;;
  south)
    # Find the closest display below (higher y)
    cur_bottom=$(echo "$cur_y + $cur_h" | bc)
    target_idx=$(yabai -m query --displays | jq --argjson cy "$cur_bottom" --argjson ci "$cur_idx" \
      '[.[] | select(.index != $ci and .frame.y >= ($cy - 1))] | sort_by(.frame.y) | first | .index // empty')
    ;;
  *)
    exit 1
    ;;
esac

[ -z "$target_idx" ] && exit 1

# Find a visible standard window on the target display and focus it directly
win=$(yabai -m query --windows --display "$target_idx" | jq -r \
  '[.[] | select(."is-visible" == true and .subrole == "AXStandardWindow")] | .[0] | .id // empty')

[ -n "$win" ] && yabai -m window --focus "$win"

#!/usr/bin/env bash
set -uo pipefail

# herdr action: toggle-watch. Opens a live `hunk diff --watch` split beside the
# focused pane, or closes it if a pane labeled "hunk" already exists in the
# focused pane's tab. Two-state toggle only (open <-> close); herdr's CLI has
# no direct "focus this pane_id" command, only tab-level or directional pane
# focus, so a third "focus existing but unfocused" state isn't implemented.
#
# Field names (pane_id, tab_id, cwd, focused, label) and the split/context JSON
# shapes below are unverified against a live payload; confirm via
# `herdr plugin log list` if this misbehaves.

HERDR="${HERDR_BIN_PATH:-herdr}"

ctx="${HERDR_PLUGIN_CONTEXT_JSON:-}"
focused_pane=$(printf '%s' "$ctx" | jq -r '.focused_pane_id // empty' 2>/dev/null || true)
cwd=$(printf '%s' "$ctx" | jq -r '.focused_pane_cwd // .workspace_cwd // empty' 2>/dev/null || true)

panes=$("$HERDR" pane list 2>/dev/null) || panes=""

if [ -z "$focused_pane" ]; then
  focused_pane=$(printf '%s' "$panes" | jq -r '[.result.panes[]? | select(.focused == true)][0].pane_id // empty' 2>/dev/null || true)
fi
if [ -z "$focused_pane" ]; then
  echo "toggle-watch: no focused pane" >&2
  exit 1
fi

tab_id=$(printf '%s' "$panes" | jq -r --arg pid "$focused_pane" '[.result.panes[]? | select(.pane_id == $pid)][0].tab_id // empty' 2>/dev/null || true)
if [ -z "$cwd" ]; then
  cwd=$(printf '%s' "$panes" | jq -r --arg pid "$focused_pane" '[.result.panes[]? | select(.pane_id == $pid)][0].cwd // empty' 2>/dev/null || true)
fi
[ -d "$cwd" ] || cwd="$HOME"

hunk_pane=$(printf '%s' "$panes" | jq -r --arg tid "$tab_id" '[.result.panes[]? | select(.tab_id == $tid and .label == "hunk")][0].pane_id // empty' 2>/dev/null || true)

if [ -n "$hunk_pane" ]; then
  exec "$HERDR" pane close "$hunk_pane"
fi

new_pane=$("$HERDR" pane split "$focused_pane" --direction right --cwd "$cwd" --focus 2>/dev/null \
  | jq -r '.result.pane.pane_id // empty' 2>/dev/null || true)
if [ -z "$new_pane" ]; then
  echo "toggle-watch: failed to open split" >&2
  exit 1
fi

"$HERDR" pane rename "$new_pane" hunk >/dev/null 2>&1 || true
exec "$HERDR" pane run "$new_pane" "hunk diff --watch"

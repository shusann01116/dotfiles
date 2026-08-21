#!/usr/bin/env bash
set -uo pipefail

# herdr action: pick-pr. Opens an interactive PR picker split beside the
# focused pane; the picker (picker.sh) checks out the selected PR's head
# branch as a worktree-backed workspace. CWD = plugin directory.
#
# Focused-pane resolution mirrors hunk-diff's toggle-watch.sh: prefer
# HERDR_PLUGIN_CONTEXT_JSON, fall back to `pane list`. Field names
# (focused_pane_id, focused_pane_cwd, workspace_cwd) verified live against
# herdr 0.7 via `plugin action invoke` context output.

HERDR="${HERDR_BIN_PATH:-herdr}"
PLUGIN_DIR=$(cd "$(dirname "$0")" && pwd)

ctx="${HERDR_PLUGIN_CONTEXT_JSON:-}"
focused_pane=$(printf '%s' "$ctx" | jq -r '.focused_pane_id // empty' 2>/dev/null || true)
cwd=$(printf '%s' "$ctx" | jq -r '.focused_pane_cwd // .workspace_cwd // empty' 2>/dev/null || true)

panes=$("$HERDR" pane list 2>/dev/null) || panes=""
if [ -z "$focused_pane" ]; then
  focused_pane=$(printf '%s' "$panes" | jq -r '[.result.panes[]? | select(.focused == true)][0].pane_id // empty' 2>/dev/null || true)
fi
if [ -z "$focused_pane" ]; then
  echo "pick-pr: no focused pane" >&2
  exit 1
fi
if [ -z "$cwd" ]; then
  cwd=$(printf '%s' "$panes" | jq -r --arg pid "$focused_pane" '[.result.panes[]? | select(.pane_id == $pid)][0].cwd // empty' 2>/dev/null || true)
fi

if [ -z "$cwd" ]; then
  echo "pick-pr: could not resolve focused pane cwd" >&2
  exit 1
fi

# global-safe guard: only act inside a git repository (message lands in
# `herdr plugin log`).
repo=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null) \
  || { echo "pick-pr: $cwd is not inside a git repository" >&2; exit 0; }

new_pane=$("$HERDR" pane split "$focused_pane" --direction right --cwd "$repo" --focus 2>/dev/null \
  | jq -r '.result.pane.pane_id // empty' 2>/dev/null || true)
if [ -z "$new_pane" ]; then
  echo "pick-pr: failed to open picker pane" >&2
  exit 1
fi
"$HERDR" pane rename "$new_pane" pr-pick >/dev/null 2>&1 || true

# Escape embedded single quotes before wrapping the path in single quotes
# (same idiom as worktree-bootstrap's dispatch.sh).
picker_q=${PLUGIN_DIR//\'/\'\\\'\'}
exec "$HERDR" pane run "$new_pane" "PR_PICK_PANE=$new_pane bash '$picker_q/picker.sh'"

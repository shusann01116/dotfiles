#!/usr/bin/env bash
set -euo pipefail

# herdr worktree.created dispatcher (generic, global-safe).
# CWD = plugin directory. On a new worktree, if the repo's MAIN worktree has an
# executable `.herdr/setup`, open a visible "setup" tab in the new workspace and
# run it there. No-op for repos without `.herdr/setup`.
#
# The exact HERDR_PLUGIN_EVENT_JSON / `tab create --json` field names are not
# documented; the jq expressions below accept the plausible candidates and fall
# back to the socket API. Confirm against a real payload via
# `herdr plugin log list` before relying on it.

HERDR="${HERDR_BIN_PATH:-herdr}"

payload="${HERDR_PLUGIN_EVENT_JSON:-}"
[ -n "$payload" ] || { echo "dispatch: no HERDR_PLUGIN_EVENT_JSON" >&2; exit 0; }

# jq must not abort the hook (set -e) on malformed JSON — fall through to the
# graceful no-op below instead of exiting non-zero.
wt=$(printf '%s' "$payload" | jq -r '.checkout_path // .worktree.checkout_path // .path // empty' 2>/dev/null || true)
ws=$(printf '%s' "$payload" | jq -r '.workspace_id // .open_workspace_id // .workspace.id // empty' 2>/dev/null || true)
[ -n "$ws" ] || ws="${HERDR_WORKSPACE_ID:-}"

# Socket-API fallback for the checkout path when the payload field name differs.
if [ -z "$wt" ] && [ -n "$ws" ]; then
  wt=$("$HERDR" worktree list --json 2>/dev/null \
    | jq -r --arg ws "$ws" '.worktrees[]? | select(.open_workspace_id == $ws) | .checkout_path' 2>/dev/null \
    | head -1 || true)
fi

if [ -z "$wt" ] || [ -z "$ws" ]; then
  echo "dispatch: cannot resolve worktree ($wt) or workspace ($ws)" >&2
  exit 0
fi

# The first `worktree ` line of --porcelain output is the main worktree. Take the
# whole path after the prefix (no field-splitting) so paths with spaces survive.
main=$(git -C "$wt" worktree list --porcelain 2>/dev/null \
  | awk '/^worktree /{sub(/^worktree /, ""); print; exit}' || true)
setup="$main/.herdr/setup"

# global-safe guard: opt-in repos only
[ -x "$setup" ] || exit 0

echo "dispatch: bootstrapping $wt via $setup (workspace $ws)" >&2

pane=$("$HERDR" tab create --workspace "$ws" --cwd "$wt" --label setup --json 2>/dev/null \
  | jq -r '.pane_id // .focused_pane_id // .pane.id // empty' 2>/dev/null || true)

if [ -z "$pane" ]; then
  echo "dispatch: failed to resolve setup pane id" >&2
  exit 1
fi

# Escape embedded single quotes before wrapping the path in single quotes for the
# command string handed to `pane run` (' -> '\'').
setup_q=${setup//\'/\'\\\'\'}
"$HERDR" pane run "$pane" "bash '$setup_q'"
